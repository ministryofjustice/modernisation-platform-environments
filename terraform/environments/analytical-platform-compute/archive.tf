data "archive_file" "airflow_plugins" {
  type        = "zip"
  source_dir  = "src/airflow/plugins"
  output_path = "plugins.zip"
}
