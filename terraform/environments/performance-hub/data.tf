data "template_file" "launch-template" {
  template = file("templates/user-data.txt")
  vars = {
    cluster_name = local.application_name
    environment  = local.environment
  }
}

data "template_file" "task_definition" {
  template = file("templates/task_definition.json")
  vars = {
    app_name                         = local.application_name
    env_name                         = local.environment
    system_account_id                = local.app_data.accounts[local.environment].system_account_id
    ecr_url                          = format("%s%s%s%s", local.environment_management.account_ids["core-shared-services-production"], ".dkr.ecr.", local.app_data.accounts[local.environment].region, ".amazonaws.com/performance-hub-ecr-repo")
    server_port                      = local.app_data.accounts[local.environment].server_port
    aws_region                       = local.app_data.accounts[local.environment].region
    container_version                = local.app_data.accounts[local.environment].container_version
    db_host                          = aws_db_instance.database.address
    db_user                          = local.app_data.accounts[local.environment].db_user
    db_password                      = aws_secretsmanager_secret_version.db_password.arn
    mojhub_cnnstr                    = aws_secretsmanager_secret_version.mojhub_cnnstr.arn
    mojhub_membership                = aws_secretsmanager_secret_version.mojhub_membership.arn
    govuk_notify_api_key             = aws_secretsmanager_secret_version.govuk_notify_api_key.arn
    os_vts_api_key                   = aws_secretsmanager_secret_version.os_vts_api_key.arn
    storage_bucket                   = "${aws_s3_bucket.upload_files.id}"
    friendly_name                    = local.app_data.accounts[local.environment].friendly_name
    hub_wwwroot                      = local.app_data.accounts[local.environment].hub_wwwroot
    pecs_basm_prod_access_key_id     = aws_secretsmanager_secret_version.pecs_basm_prod_access_key_id.arn
    pecs_basm_prod_secret_access_key = aws_secretsmanager_secret_version.pecs_basm_prod_secret_access_key.arn
    ap_import_access_key_id          = aws_secretsmanager_secret_version.ap_import_access_key_id.arn
    ap_import_secret_access_key      = aws_secretsmanager_secret_version.ap_import_secret_access_key.arn
    ap_export_access_key_id          = aws_secretsmanager_secret_version.ap_export_access_key_id.arn
    ap_export_secret_access_key      = aws_secretsmanager_secret_version.ap_export_secret_access_key.arn
  }
}
