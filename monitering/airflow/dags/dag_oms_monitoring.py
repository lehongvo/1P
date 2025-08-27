from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from o2o_ops import (
    op_fetch_recent,
    op_validate_rows,
    op_transform_enrich,
    op_classify_flags,
    op_upsert_fact,
    op_upsert_agg,
    op_push_metrics,
)

DEFAULT_ARGS = {
  'owner': 'de',
  'retries': 1,
  'retry_delay': timedelta(minutes=1),
}

with DAG(
    dag_id='o2o_oms_monitoring',
    start_date=datetime(2025, 1, 1),
    schedule_interval='*/1 * * * *',
    catchup=False,
    default_args=DEFAULT_ARGS,
    max_active_runs=1,
) as dag:

    fetch_recent = PythonOperator(
        task_id='fetch_recent',
        python_callable=op_fetch_recent,
        op_kwargs={'minutes': 5, 'limit': 1000}
    )

    validate = PythonOperator(
        task_id='validate_rows',
        python_callable=op_validate_rows,
        op_kwargs={'payload': "{{ ti.xcom_pull(task_ids='fetch_recent') | tojson }}"},
    )

    transform = PythonOperator(
        task_id='transform_enrich',
        python_callable=op_transform_enrich,
        op_kwargs={'rows': "{{ ti.xcom_pull(task_ids='validate_rows') | tojson }}"},
    )

    classify = PythonOperator(
        task_id='classify_flags',
        python_callable=op_classify_flags,
        op_kwargs={'rows': "{{ ti.xcom_pull(task_ids='transform_enrich') | tojson }}"},
    )

    upsert_fact = PythonOperator(
        task_id='upsert_fact',
        python_callable=op_upsert_fact,
        op_kwargs={'rows': "{{ ti.xcom_pull(task_ids='classify_flags') | tojson }}"},
    )

    upsert_agg = PythonOperator(
        task_id='upsert_agg',
        python_callable=op_upsert_agg,
    )

    push_metrics = PythonOperator(
        task_id='push_metrics',
        python_callable=op_push_metrics,
        op_kwargs={'rows': "{{ ti.xcom_pull(task_ids='classify_flags') | tojson }}"},
    )

    fetch_recent >> validate >> transform >> classify >> upsert_fact >> [upsert_agg, push_metrics]
