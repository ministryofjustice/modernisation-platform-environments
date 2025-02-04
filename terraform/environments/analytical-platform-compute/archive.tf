data "archive_file" "airflow_plugins" {
  type        = "zip"
  output_path = "plugins.zip"

  source {
    content  = file("src/airflow/local-settings/${local.environment}/airflow_local_settings.py")
    filename = "airflow_local_settings.py"
  }

  source {
    content  = file("src/airflow/plugins/analytical_platform_menu_links.py")
    filename = "analytical_platform_menu_links.py"
  }
}
