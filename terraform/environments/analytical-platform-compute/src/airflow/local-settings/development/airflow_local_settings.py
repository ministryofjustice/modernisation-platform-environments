from airflow.www.utils import UIAlert

# This is desribed;
# here https://airflow.apache.org/docs/apache-airflow/2.4.3/howto/customize-ui.html#add-custom-alert-messages-on-the-dashboard
# and here https://github.com/apache/airflow/blob/main/airflow/www/utils.py#L889
DASHBOARD_UIALERTS = [
    UIAlert(
        'Analytical Platform Airflow Service',
        category="info",
        html=True,
    )
]
