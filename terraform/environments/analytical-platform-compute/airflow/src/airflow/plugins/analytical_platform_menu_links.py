from airflow.plugins_manager import AirflowPlugin

analytical_platform_status_page = {
    "category": "Analytical Platform",
    "name": "Status",
    "href": "https://status.analytical-platform.service.justice.gov.uk/",
}

analytical_platform_user_guide = {
    "category": "Analytical Platform",
    "name": "User Guidance",
    "href": "https://user-guidance.analytical-platform.service.justice.gov.uk/services/airflow",
}

analytical_platform_container_registry = {
    "category": "Analytical Platform",
    "name": "Container Registry",
    "href": "https://moj.awsapps.com/start/#/console?account_id=509399598587&role_name=modernisation-platform-mwaa-user&destination=https%3A%2F%2Feu-west-2.console.aws.amazon.com%2Fecr%2Fprivate-registry%2Frepositories%3Fregion%3Deu-west-2",
}

class AnalyticalPlatformMenuLinksPlugin(AirflowPlugin):
    name = "Analytical Platform Menu Links Plugin"
    appbuilder_menu_items = [
        analytical_platform_status_page,
        analytical_platform_user_guide,
        analytical_platform_container_registry,
    ]
