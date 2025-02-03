from airflow.plugins_manager import AirflowPlugin

analytical_platform_status_page = {
    "name": "Status",
    "href": "https://status.analytical-platform.service.justice.gov.uk/",
    "category": "Analytical Platform",
}

analytical_platform_user_guide = {
    "name": "User Guide",
    "href": "https://user-guide.analytical-platform.service.justice.gov.uk/",
    "category": "Analytical Platform",
}


class AnalyticalPlatformMenuLinksPlugin(AirflowPlugin):
    name = "Analytical Platform Menu Links Plugin"
    appbuilder_menu_items = [
        analytical_platform_status_page,
        analytical_platform_user_guide
    ]
