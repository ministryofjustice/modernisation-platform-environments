resource "null_resource" "update_mwaa" {
  triggers = {
    airflow_local_settings_object = module.airflow_local_settings_object.s3_object_version_id
  }

  provisioner "local-exec" {
    command = "bash scripts/update-mwaa-environment.sh ${local.environment}"
  }

  depends_on = [aws_mwaa_environment.main]
}
