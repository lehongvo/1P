# LOTUS O2O Monitoring POC - Step by Step (DE Guide)

Mục tiêu: Dựng full luồng giám sát OMS → Commerce với stack Prometheus + Mimir + Grafana + Alertmanager + Airflow + PostgreSQL. Có thể chạy local bằng Docker.

## 0) Prerequisites
- Docker / Docker Compose v2
- curl, jq
- Source đã chạy: OMS (3001), Commerce (3002), Postgres (5432)

## 1) Kiến trúc tổng quan
- Phoenix OMS
  - Expose endpoint monitoring: `/api/v1/monitor/recent?minutes=...` (yêu cầu x-api-key)
  - Auto-advance cron 30s → sinh luồng trạng thái để quan sát
- Prometheus
  - Scrape exporter (node/exporter hoặc custom OMS exporter)
  - Pull metrics rules từ file rules
- Mimir (remote-write)
  - Lưu trữ metrics dài hạn (s3-compatible optional)
- Alertmanager
  - Nhận alerts từ Prometheus và gửi thông báo (email/slack – POC: log)
- Grafana
  - Data source: Prometheus (hoặc Mimir/Prometheus)
  - Dashboards: status counts, success rate, delay ratio
- Airflow
  - DAG ingest data OMS → warehouse (Postgres) + tính aggregates
  - Đẩy metrics/alerts phụ trợ

## 2) Thư mục cấu hình
Tạo thư mục `monitoring-stack/` (nằm cạnh project) với cấu trúc:
```
monitoring-stack/
  docker-compose.yml
  prometheus/
    prometheus.yml
    rules/
      alerts.yml
  grafana/
    provisioning/
      datasources/datasource.yml
      dashboards/dashboard.yml
    dashboards/
      o2o_overview.json (optional)
  alertmanager/
    config.yml
  airflow/
    dags/
      dag_oms_monitoring.py
  README.md
```

## 3) docker-compose (Prometheus, Mimir, Grafana, Alertmanager, Airflow)
File `monitoring-stack/docker-compose.yml` (rút gọn – có thể chỉnh sửa tuỳ môi trường):
```yaml
version: '3.8'

networks:
  mon:
    driver: bridge

volumes:
  prom_data:
  grafana_data:
  airflow_data:

services:
  prometheus:
    image: prom/prometheus:v2.54.1
    container_name: prom
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/rules:/etc/prometheus/rules:ro
      - prom_data:/prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.path=/prometheus
    ports:
      - "9090:9090"
    networks: [mon]

  mimir:
    image: grafana/mimir:2.12.0
    container_name: mimir
    command: ["-target=all", "-config.expand-env=true"]
    environment:
      MIMIR_SERVER_HTTP_LISTEN_PORT: 9009
    ports:
      - "9009:9009"
    networks: [mon]

  alertmanager:
    image: prom/alertmanager:v0.27.0
    container_name: alertmanager
    volumes:
      - ./alertmanager/config.yml:/etc/alertmanager/config.yml:ro
    command: ["--config.file=/etc/alertmanager/config.yml"]
    ports:
      - "9093:9093"
    networks: [mon]

  grafana:
    image: grafana/grafana:11.1.0
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: admin
    networks: [mon]

  airflow:
    image: apache/airflow:2.9.3
    container_name: airflow
    environment:
      AIRFLOW__CORE__LOAD_EXAMPLES: "false"
      AIRFLOW__WEBSERVER__RBAC: "true"
      _PIP_ADDITIONAL_REQUIREMENTS: "psycopg2-binary requests"
    ports:
      - "8080:8080"
    volumes:
      - airflow_data:/opt/airflow
      - ./airflow/dags:/opt/airflow/dags
    command: ["bash", "-lc", "airflow db init && airflow users create -u admin -p admin -r Admin -e admin@example.com -f Admin -l User && airflow webserver & airflow scheduler"]
    networks: [mon]
```

## 4) Prometheus config
File `monitoring-stack/prometheus/prometheus.yml`:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/rules/alerts.yml

scrape_configs:
  # Scrape node or cAdvisor nếu cần
  - job_name: 'self'
    static_configs:
      - targets: ['prom:9090']

  # OMS custom exporter (tuỳ chọn)
  # Nếu chưa có exporter, có thể dùng blackbox/http prober hoặc bỏ qua.
  # Ví dụ: scrape OMS /health dưới dạng exporter giả lập.
  - job_name: 'oms-health'
    metrics_path: /api/v1/health
    scheme: http
    static_configs:
      - targets: ['phoenix_oms:3001']
```

File `monitoring-stack/prometheus/rules/alerts.yml`:
```yaml
groups:
  - name: o2o.rules
    rules:
      - alert: NoNewOrders
        expr: increase(o2o_orders_ingested_total[10m]) == 0
        for: 10m
        labels:
          severity: warning
        annotations:
          description: No new orders ingested in 10 minutes.

      - alert: TooManyFailures
        expr: (o2o_orders_failed_total / o2o_orders_ingested_total) > 0.05
        for: 10m
        labels:
          severity: critical
        annotations:
          description: Failure ratio exceeds 5% in last 10m.
```
Ghi chú: Các metric `o2o_*` có thể được đẩy bởi Airflow DAG (pushgateway) hoặc exporter.

## 5) Alertmanager config
File `monitoring-stack/alertmanager/config.yml`:
```yaml
global:
  resolve_timeout: 5m
route:
  receiver: 'log'
receivers:
  - name: 'log'
    webhook_configs:
      - url: 'http://prom:9090/-/reload'  # POC: dummy webhook; thực tế đổi sang Slack/Email gateway
```
(POC có thể đổi sang stdout receiver khác hoặc webhook mock.)

## 6) Grafana provisioning
File `monitoring-stack/grafana/provisioning/datasources/datasource.yml`:
```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prom:9090
    isDefault: true
```

File `monitoring-stack/grafana/provisioning/dashboards/dashboard.yml`:
```yaml
apiVersion: 1
dashboardProviders:
  - name: 'default'
    orgId: 1
    folder: 'O2O'
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /var/lib/grafana/dashboards
```

Bạn có thể import dashboard JSON sau khi có metrics (hoặc tạo panel mới trong UI).

## 7) Airflow DAG (ingest OMS → Postgres + metrics)
File `monitoring-stack/airflow/dags/dag_oms_monitoring.py` (rút gọn):
```python
from datetime import datetime, timedelta
import os, requests, psycopg2
from airflow import DAG
from airflow.operators.python import PythonOperator

API_KEY = os.getenv('OMS_API_KEY', '0x9f299A715cb6aF84e93ba90371538Ddf130E1ec0021hf902')
OMS_URL = os.getenv('OMS_URL', 'http://host.docker.internal:3001')
PG_DSN = os.getenv('PG_DSN', 'dbname=lotus_o2o user=lotus_user password=lotus_password host=host.docker.internal port=5432')

DEFAULT_ARGS = {
  'owner': 'de',
  'retries': 1,
  'retry_delay': timedelta(minutes=1),
}

def fetch_recent_orders(**ctx):
    minutes = ctx['params'].get('minutes', 5)
    r = requests.get(f"{OMS_URL}/api/v1/monitor/recent?minutes={minutes}&limit=1000",
                     headers={'x-api-key': API_KEY}, timeout=30)
    r.raise_for_status()
    return r.json()

def load_to_postgres(**ctx):
    payload = ctx['ti'].xcom_pull(task_ids='fetch_recent')
    rows = payload.get('data', [])
    conn = psycopg2.connect(PG_DSN)
    cur = conn.cursor()
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
        ingested_at timestamp default now()
      )
    """)
    for r in rows:
      cur.execute("""
        INSERT INTO fact_orders_monitoring (order_id, customer_id, customer_name, status, order_type, total_amount, updated_at, item_name, item_detail)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT (order_id) DO UPDATE SET
          customer_id=excluded.customer_id,
          customer_name=excluded.customer_name,
          status=excluded.status,
          order_type=excluded.order_type,
          total_amount=excluded.total_amount,
          updated_at=excluded.updated_at,
          item_name=excluded.item_name,
          item_detail=excluded.item_detail
      """, (
          r.get('order_id'), r.get('customer_id'), r.get('customer_name'),
          r.get('status'), r.get('order_type'), r.get('total_amount'),
          r.get('updated_at'), r.get('item_name'), r.get('item_detail')
      ))
    conn.commit(); cur.close(); conn.close()

with DAG(
    dag_id='o2o_oms_monitoring',
    start_date=datetime(2025, 1, 1),
    schedule_interval='*/1 * * * *',  # mỗi phút
    catchup=False,
    default_args=DEFAULT_ARGS,
    max_active_runs=1,
) as dag:

    fetch_recent = PythonOperator(
        task_id='fetch_recent',
        python_callable=fetch_recent_orders,
        params={'minutes': 5}
    )

    load_fact = PythonOperator(
        task_id='load_fact',
        python_callable=load_to_postgres,
    )

    fetch_recent >> load_fact
```

Chạy Airflow:
```bash
cd monitoring-stack
docker compose up -d
# Mở http://localhost:8080 (admin/admin), bật DAG o2o_oms_monitoring
```

## 8) Kiểm thử end-to-end
- Seed 10 orders PENDING:
```bash
curl -s -X POST 'http://localhost:3001/api/v1/seed-mock-data?count=10' \
  -H 'x-api-key: 0x9f299A715cb6aF84e93ba90371538Ddf130E1ec0021hf902' | jq .
```
- Chờ cron OMS tự đẩy trạng thái. Gọi monitoring để quan sát:
```bash
curl -s 'http://localhost:3001/api/v1/monitor/recent?minutes=10&limit=5' \
  -H 'x-api-key: 0x9f299A715cb6aF84e93ba90371538Ddf130E1ec0021hf902' | jq '{total, statusCounts, sample: .data[0:3]}'
```
- Mở Prometheus: http://localhost:9090
- Mở Grafana: http://localhost:3000 (admin/admin)
- Mở Alertmanager: http://localhost:9093
- Mở Airflow: http://localhost:8080

## 9) Mở rộng (sau POC)
- Thêm Pushgateway để đẩy metrics `o2o_orders_*` từ Airflow
- Tạo Grafana dashboards: success rate, delays, per-order trace (table)
- Tích hợp Slack/Email thật cho Alertmanager
- Tối ưu retention Mimir, thêm object storage (S3/MinIO)

## 10) Ghi chú bảo mật
- OMS yêu cầu `x-api-key` cho mọi API (trừ /health). Trong Airflow, set `OMS_API_KEY` qua env/secret.
- Không hardcode secrets trong repo; dùng `.env` hoặc vault.

## 11) Sự cố thường gặp
- Postgres init lỗi `CREATE TYPE IF NOT EXISTS`: đã đổi sang DO $$ … $$ trong init.sql.
- Monitoring trả `item_id` thay vì `item_name/detail`: đã sửa SELECT JOIN, cần rebuild/restart OMS.
- 401 Unauthorized: thiếu header `x-api-key`.

---
Checklist triển khai nhanh:
1) `docker compose up -d` trong `monitoring-stack/`
2) Bật DAG `o2o_oms_monitoring` trong Airflow
3) Seed orders và kiểm tra Prometheus/Grafana/Alertmanager
4) Điều chỉnh rules/threshold theo PRD `System Monitoring Dashboard  LOTUS’S-O2O.txt`

---

## 12) Implementation Task Board (Professional Plan)

Use this checklist to implement the POC in small, verifiable steps. Each step includes actions, commands, and acceptance criteria.

### Step 1 — Bootstrap repository structure
- [ ] Create `monitoring-stack/` with subfolders: `prometheus/`, `prometheus/rules/`, `grafana/provisioning/{datasources,dashboards}/`, `grafana/dashboards/`, `alertmanager/`, `airflow/dags/`
- [ ] Add `docker-compose.yml` (as in section 3)
- [ ] Add `.env` (optional) for secrets

Acceptance:
- [ ] `tree monitoring-stack/` shows the exact structure

### Step 2 — Verify OMS and PostgreSQL
- [ ] OMS health: `curl -s http://localhost:3001/api/v1/health | jq .`
- [ ] Seed orders: `curl -s -X POST 'http://localhost:3001/api/v1/seed-mock-data?count=5' -H 'x-api-key: <API_KEY>' | jq .`
- [ ] Recent monitoring: `curl -s 'http://localhost:3001/api/v1/monitor/recent?minutes=10' -H 'x-api-key: <API_KEY>' | jq '{total,statusCounts,sample:.data[0:3]}'`

Acceptance:
- [ ] Response contains `item_name` and `item_detail` (no `item_id`)
- [ ] StatusCounts reflect cron auto-advance

### Step 3 — Bring up monitoring stack
```bash
cd monitoring-stack
docker compose up -d
```
Acceptance:
- [ ] Prometheus UI at http://localhost:9090 is up
- [ ] Grafana at http://localhost:3000 (admin/admin)
- [ ] Alertmanager at http://localhost:9093
- [ ] Airflow at http://localhost:8080 (admin/admin)

### Step 4 — Configure Prometheus scrapes & rules
- [ ] Edit `prometheus/prometheus.yml` (section 4)
- [ ] Add/adjust `prometheus/rules/alerts.yml`
- [ ] Reload Prometheus: `docker exec -it prom kill -HUP 1` or restart service

Acceptance:
- [ ] Rules listed in Prom UI → Status → Rules
- [ ] Targets healthy in Prom UI → Status → Targets

### Step 5 — Configure Alertmanager
- [ ] Write `alertmanager/config.yml` (section 5)
- [ ] Wire Prometheus `alerting` section to AM URL
- [ ] Restart Prometheus & Alertmanager

Acceptance:
- [ ] Alertmanager UI running and reachable
- [ ] Test alert via Prometheus “/alerts” page becomes firing when expression is forced

### Step 6 — Provision Grafana data source & dashboards
- [ ] `grafana/provisioning/datasources/datasource.yml` points to Prometheus `http://prom:9090`
- [ ] `grafana/provisioning/dashboards/dashboard.yml` configured to load dashboards from `/var/lib/grafana/dashboards`
- [ ] Create dashboards/panels: Success rate, Failure/Delay %, Orders by status (10m), Recent orders table

Acceptance:
- [ ] Grafana panels show time-series and correlate with Prometheus queries

### Step 7 — Deploy Airflow DAG (OMS → Postgres)
- [ ] Place `airflow/dags/dag_oms_monitoring.py`
- [ ] Set environment in `docker-compose.yml` for `OMS_URL`, `OMS_API_KEY`, `PG_DSN`
- [ ] Initialize Airflow DB & user (handled by compose command)
- [ ] Enable DAG `o2o_oms_monitoring`

Acceptance:
- [ ] DAG runs every minute, no failures in graph/logs
- [ ] Table `fact_orders_monitoring` populated and updated

### Step 8 — Metrics & Alerts Validation
- [ ] (Optional) Push metrics from Airflow to Pushgateway/Prom
- [ ] Trigger “No new orders” by pausing seeding for >10m
- [ ] Trigger “Too many failures” by forcing OMS to produce failed statuses

Acceptance:
- [ ] Alerts appear in Prometheus and are routed to Alertmanager

### Step 9 — Dashboard UX polish
- [ ] Variables: `status`, `order_type`, time window
- [ ] Panels: Top items by volume, success trend, delay trend
- [ ] Threshold coloring for KPIs

Acceptance:
- [ ] Non-technical user can answer: “Tình trạng đơn hàng 10 phút qua?”

### Step 10 — Operationalization
- [ ] Add healthchecks to compose services
- [ ] Add retention settings (Prom/Mimir)
- [ ] Document backup/restore strategy for `fact_orders_monitoring`

Acceptance:
- [ ] `README.md` updated with runbook (start/stop/troubleshoot)

### Step 11 — Security & Secrets
- [ ] Use `.env` or secrets for `OMS_API_KEY`, `PG_DSN`
- [ ] Restrict Grafana creds; rotate keys in prod

Acceptance:
- [ ] No secrets hardcoded in repo

### Step 12 — Final E2E demo script
```bash
# 1) Bring up stack
cd monitoring-stack && docker compose up -d

# 2) Seed some orders
curl -s -X POST 'http://localhost:3001/api/v1/seed-mock-data?count=10' \
  -H 'x-api-key: <API_KEY>' | jq .

# 3) Fetch recent window
curl -s 'http://localhost:3001/api/v1/monitor/recent?minutes=10&limit=5' \
  -H 'x-api-key: <API_KEY>' | jq '{total,statusCounts,sample:.data[0:3]}'

# 4) Open UIs
open http://localhost:9090; open http://localhost:3000; open http://localhost:8080; open http://localhost:9093
```

This plan aligns with PRD “System Monitoring Dashboard LOTUS’S-O2O” and supports scale-out to other downstream systems after the POC.
