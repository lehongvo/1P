from __future__ import annotations
from typing import Any, Dict, List, Tuple, Union
from datetime import datetime
import os, json, time
import requests
import psycopg2

API_KEY = os.getenv('OMS_API_KEY', '0x9f299A715cb6aF84e93ba90371538Ddf130E1ec0021hf902')
OMS_URL = os.getenv('OMS_URL', 'http://host.docker.internal:3001')
PG_DSN = os.getenv('PG_DSN', 'dbname=lotus_o2o user=lotus_user password=lotus_password host=host.docker.internal port=5432')

# ----------------------------
# Utils
# ----------------------------

def _ensure_dict(obj: Union[str, Dict[str, Any]]) -> Dict[str, Any]:
    if isinstance(obj, dict):
        return obj
    if isinstance(obj, str):
        try:
            return json.loads(obj)
        except Exception:
            return {}
    return {}

def _ensure_list(obj: Union[str, List[Dict[str, Any]]]) -> List[Dict[str, Any]]:
    if isinstance(obj, list):
        return obj
    if isinstance(obj, str):
        try:
            parsed = json.loads(obj)
            return parsed if isinstance(parsed, list) else []
        except Exception:
            return []
    return []

# ----------------------------
# Ingestion
# ----------------------------

def op_fetch_recent(minutes: int = 50, limit: int = 1000) -> Dict[str, Any]:
    r = requests.get(f"{OMS_URL}/api/v1/monitor/recent?minutes={minutes}&limit={limit}",
                     headers={'x-api-key': API_KEY}, timeout=60)
    r.raise_for_status()
    return r.json()

# ----------------------------
# DQC (basic)
# ----------------------------

def op_validate_rows(payload: Union[str, Dict[str, Any]]) -> List[Dict[str, Any]]:
    payload_dict = _ensure_dict(payload)
    rows = payload_dict.get('data', [])
    if isinstance(rows, str):
        rows = _ensure_list(rows)
    valid: List[Dict[str, Any]] = []
    for r in rows:
        if not r.get('order_id') or not r.get('status') or not r.get('updated_at'):
            continue
        valid.append(r)
    return valid

# ----------------------------
# Transform & Enrich
# ----------------------------

STATUS_SET = {
    'PENDING', 'PENDING_PAYMENT', 'PROCESSING', 'COMPLETE', 'CLOSED',
    'CANCELED', 'HOLDED', 'PAYMENT_REVIEW', 'FRAUD', 'SHIPPING'
}

ORDER_TYPES = {'ONLINE','OFFLINE','INSTORE','MARKETPLACE','CALLCENTER'}


def op_transform_enrich(rows: Union[str, List[Dict[str, Any]]]) -> List[Dict[str, Any]]:
    rows = _ensure_list(rows) if isinstance(rows, str) else rows
    out: List[Dict[str, Any]] = []
    for r in rows:
        # normalize enums
        status = str(r.get('status', '')).upper()
        order_type = str(r.get('order_type', '')).upper()
        if status not in STATUS_SET:
            status = 'PENDING'
        if order_type not in ORDER_TYPES:
            order_type = 'ONLINE'
        out.append({
            'order_id': r.get('order_id'),
            'customer_id': r.get('customer_id'),
            'customer_name': r.get('customer_name'),
            'status': status,
            'order_type': order_type,
            'total_amount': r.get('total_amount'),
            'updated_at': r.get('updated_at'),
            'item_name': r.get('item_name'),
            'item_detail': r.get('item_detail')
        })
    return out

# ----------------------------
# Classification (Success/Failed/Delayed)
# ----------------------------

def op_classify_flags(rows: Union[str, List[Dict[str, Any]]]) -> List[Dict[str, Any]]:
    rows = _ensure_list(rows) if isinstance(rows, str) else rows
    def classify_status(s: str) -> Tuple[bool, bool, bool]:
        success = s in {'COMPLETE', 'CLOSED'}
        failed = s in {'CANCELED', 'FRAUD'}
        delayed = s in {'PENDING','PENDING_PAYMENT','PROCESSING','HOLDED','PAYMENT_REVIEW','SHIPPING'} and not (success or failed)
        return success, failed, delayed

    out: List[Dict[str, Any]] = []
    for r in rows:
        s, f, d = classify_status(r['status'])
        r2 = dict(r)
        r2.update({'is_success': s, 'is_failed': f, 'is_delayed': d})
        out.append(r2)
    return out

# ----------------------------
# Load: Postgres fact + aggregates
# ----------------------------

def _pg_conn():
    return psycopg2.connect(PG_DSN)


def op_upsert_fact(rows: Union[str, List[Dict[str, Any]]]) -> int:
    rows = _ensure_list(rows) if isinstance(rows, str) else rows
    if not rows:
        return 0
    conn = _pg_conn(); cur = conn.cursor()
    cur.execute("""
      CREATE TABLE IF NOT EXISTS fact_orders_monitoring (
        order_id text primary key,
        customer_id text,
        customer_name text,
        status text,
        order_type text,
        total_amount numeric,
        updated_at timestamp,
        item_name text,
        item_detail text,
        is_success boolean,
        is_failed boolean,
        is_delayed boolean,
        ingested_at timestamp default now()
      )
    """)
    count = 0
    for r in rows:
        cur.execute("""
          INSERT INTO fact_orders_monitoring (order_id, customer_id, customer_name, status, order_type, total_amount, updated_at, item_name, item_detail, is_success, is_failed, is_delayed)
          VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
          ON CONFLICT (order_id) DO UPDATE SET
            customer_id=excluded.customer_id,
            customer_name=excluded.customer_name,
            status=excluded.status,
            order_type=excluded.order_type,
            total_amount=excluded.total_amount,
            updated_at=excluded.updated_at,
            item_name=excluded.item_name,
            item_detail=excluded.item_detail,
            is_success=excluded.is_success,
            is_failed=excluded.is_failed,
            is_delayed=excluded.is_delayed
        """, (
            r['order_id'], r.get('customer_id'), r.get('customer_name'), r['status'], r['order_type'],
            r.get('total_amount'), r['updated_at'], r.get('item_name'), r.get('item_detail'),
            r['is_success'], r['is_failed'], r['is_delayed']
        ))
        count += 1
    conn.commit(); cur.close(); conn.close()
    return count


def op_upsert_agg() -> int:
    conn = _pg_conn(); cur = conn.cursor()
    # Ensure fact table exists (idempotent) so aggregation won't fail on first run
    cur.execute(
        """
      CREATE TABLE IF NOT EXISTS fact_orders_monitoring (
        order_id text primary key,
        customer_id text,
        customer_name text,
        status text,
        order_type text,
        total_amount numeric,
        updated_at timestamp,
        item_name text,
        item_detail text,
        is_success boolean,
        is_failed boolean,
        is_delayed boolean,
        ingested_at timestamp default now()
      )
    """
    )
    cur.execute("""
      CREATE TABLE IF NOT EXISTS agg_orders_minutely (
        ts_minute timestamp primary key,
        success_count int,
        failed_count int,
        delayed_count int,
        total_count int
      )
    """)
    cur.execute("""
      INSERT INTO agg_orders_minutely (ts_minute, success_count, failed_count, delayed_count, total_count)
      SELECT date_trunc('minute', updated_at) as ts,
             sum(CASE WHEN is_success THEN 1 ELSE 0 END),
             sum(CASE WHEN is_failed THEN 1 ELSE 0 END),
             sum(CASE WHEN is_delayed THEN 1 ELSE 0 END),
             count(*)
      FROM fact_orders_monitoring
      WHERE updated_at >= now() - interval '1 day'
      GROUP BY 1
      ON CONFLICT (ts_minute) DO UPDATE SET
        success_count = EXCLUDED.success_count,
        failed_count  = EXCLUDED.failed_count,
        delayed_count = EXCLUDED.delayed_count,
        total_count   = EXCLUDED.total_count
    """)
    conn.commit(); cur.close(); conn.close()
    return 1

# ----------------------------
# Metrics (stub for POC)
# ----------------------------

def op_push_metrics(rows: Union[str, List[Dict[str, Any]]]) -> Dict[str, int]:
    rows = _ensure_list(rows) if isinstance(rows, str) else rows
    total = len(rows)
    success = sum(1 for r in rows if r['is_success'])
    failed = sum(1 for r in rows if r['is_failed'])
    delayed = sum(1 for r in rows if r['is_delayed'])
    # Push to Pushgateway in Prometheus text exposition format
    try:
        job = 'o2o_oms_monitoring'
        lines = []
        lines.append('# TYPE o2o_orders_total gauge')
        lines.append('o2o_orders_total %d' % total)
        lines.append('# TYPE o2o_orders_success gauge')
        lines.append('o2o_orders_success %d' % success)
        lines.append('# TYPE o2o_orders_failed gauge')
        lines.append('o2o_orders_failed %d' % failed)
        lines.append('# TYPE o2o_orders_delayed gauge')
        lines.append('o2o_orders_delayed %d' % delayed)
        payload = '\n'.join(lines) + '\n'
        # environment inside Airflow container can reach pushgateway by service name
        import requests as _req
        _req.post('http://pushgateway:9091/metrics/job/%s' % job, data=payload, timeout=5)
    except Exception:
        pass
    return {'total': total, 'success': success, 'failed': failed, 'delayed': delayed}
