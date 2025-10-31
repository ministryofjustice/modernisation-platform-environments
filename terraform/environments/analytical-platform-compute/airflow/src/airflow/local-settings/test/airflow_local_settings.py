from airflow.www.utils import UIAlert

DASHBOARD_UIALERTS = [
    UIAlert(
        'Analytical Platform Airflow Service',
        category="info",
        html=True,
    )
]
