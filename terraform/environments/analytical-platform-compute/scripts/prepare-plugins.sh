#!/usr/bin/env bash

ENVIRONMENT="${1}"

mkdir --parents dist/airflow/plugins

cp "src/airflow/local-settings/${ENVIRONMENT}/airflow_local_settings.py" "dist/airflow/plugins/airflow_local_settings.py"
cp "src/airflow/plugins/analytical_platform_menu_links.py" "dist/airflow/plugins/analytical_platform_menu_links.py"
