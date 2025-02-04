resource "null_resource" "prepare_plugins" {
  # triggers = {
  #   local_settings = filemd5("src/airflow/local-settings/development/airflow_local_settings.py")
  #   menu_links     = filemd5("src/airflow/plugins/analytical_platform_menu_links.py")
  # }

  provisioner "local-exec" {
    command = "bash scripts/prepare-plugins.sh ${local.environment}"
  }
}

data "archive_file" "airflow_plugins" {
  type        = "zip"
  source_dir  = "dist/airflow/plugins"
  output_path = "plugins.zip"

  depends_on = [null_resource.prepare_plugins]
}
