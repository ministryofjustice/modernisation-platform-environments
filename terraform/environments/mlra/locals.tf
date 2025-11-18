#### This file can be used to store locals specific to the member account ####

locals {
  env_account_id       = local.environment_management.account_ids[terraform.workspace]
  application_test_url = "https://mlra.laa-development.modernisation-platform.service.justice.gov.uk/mlra/"

  # ECS local variables for ecs.tf
  ec2_ingress_rules = {
  }
  ec2_egress_rules = {
  }

  alb_security_group_id = module.alb.security_group.id

  user_data = base64encode(templatefile("user_data.sh", {
    app_name    = local.application_name,
    environment = local.environment,
    xdr_dir     = "/tmp/cortex-agent",
    xdr_tar     = "/tmp/cortex-agent.tar.gz",
    xdr_tags    = local.xdr_tags
  }))

  maatdb_password_secret_name    = "APP_MAATDB_DBPASSWORD_MLA1"
  app_master_password_name       = "APP_MASTER_PASSWORD"
  app_salt_name                  = "APP_SALT"
  app_derivation_iterations_name = "APP_DERIVATION_ITERATIONS"
  gtm_id_secret_name             = "APP_MLRA_GOOGLE_TAG_MANAGER_ID"
  infox_client_secret_name       = "APP_INFOX_CLIENT_SECRET"
  maat_api_client_id_name        = "APP_MAAT_API_CLIENT_ID"
  maat_api_client_secret_name    = "APP_MAAT_API_CLIENT_SECRET"
  task_definition = templatefile("task_definition.json", {
    app_name                  = local.application_name
    ecr_url                   = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/mlra-ecr-repo"
    docker_image_tag          = local.application_data.accounts[local.environment].docker_image_tag
    region                    = local.application_data.accounts[local.environment].region
    maat_api_end_point        = local.application_data.accounts[local.environment].maat_api_end_point
    maat_db_url               = local.application_data.accounts[local.environment].maat_db_url
    maat_libra_wsdl_url       = local.application_data.accounts[local.environment].maat_libra_wsdl_url
    maat_api_oauth_scope      = local.application_data.accounts[local.environment].maat_api_oauth_scope
    maat_api_oauth_url        = local.application_data.accounts[local.environment].maat_api_oauth_url
    sentry_env                = local.environment
    db_secret_arn             = "arn:aws:secretsmanager:${local.application_data.accounts[local.environment].region}:${local.env_account_id}:secret:mlra/${local.maatdb_password_secret_name}"
    google_tag_manager_id     = "arn:aws:secretsmanager:${local.application_data.accounts[local.environment].region}:${local.env_account_id}:secret:mlra/${local.gtm_id_secret_name}"
    infox_client_secret       = "arn:aws:secretsmanager:${local.application_data.accounts[local.environment].region}:${local.env_account_id}:secret:mlra/${local.infox_client_secret_name}"
    maat_api_client_id        = "arn:aws:secretsmanager:${local.application_data.accounts[local.environment].region}:${local.env_account_id}:secret:mlra/${local.maat_api_client_id_name}"
    maat_api_client_secret    = "arn:aws:secretsmanager:${local.application_data.accounts[local.environment].region}:${local.env_account_id}:secret:mlra/${local.maat_api_client_secret_name}"
    app_master_password       = "arn:aws:secretsmanager:${local.application_data.accounts[local.environment].region}:${local.env_account_id}:secret:mlra/${local.app_master_password_name}"
    app_salt                  = "arn:aws:secretsmanager:${local.application_data.accounts[local.environment].region}:${local.env_account_id}:secret:mlra/${local.app_salt_name}"
    app_derivation_iterations = "arn:aws:secretsmanager:${local.application_data.accounts[local.environment].region}:${local.env_account_id}:secret:mlra/${local.app_derivation_iterations_name}"
  })
  ecs_target_capacity = 100

  # SNS local variables for cloudwatch.tf
  pagerduty_integration_keys     = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  pagerduty_integration_key_name = local.application_data.accounts[local.environment].pagerduty_integration_key_name

  xdr_tags = join(", ", [
    upper(local.application_name), upper(local.environment), upper(var.networking[0].business-unit)
  ])
}
