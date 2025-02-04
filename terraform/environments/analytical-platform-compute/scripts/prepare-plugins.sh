#!/usr/bin/env bash

ENVIRONMENT="${1}"

cp --preserve "src/airflow/local-settings/${ENVIRONMENT}/airflow_local_settings.py" "src/airflow/plugins/airflow_local_settings.py"
