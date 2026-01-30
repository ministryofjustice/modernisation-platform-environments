
##
# SSM Parameter Store for delius-core-frontend
##

resource "aws_ssm_parameter" "jdbc_url" {
  name  = format("/%s-%s/JDBC_URL", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "jdbc:oracle:thin:@//INITIAL_HOSTNAME_OVERRIDEN:INITIAL_PORT_OVERRIDDEN"
  tags  = local.tags
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

data "aws_ssm_parameter" "jdbc_url" {
  name = aws_ssm_parameter.jdbc_url.name
}


resource "aws_ssm_parameter" "jdbc_password" {
  name  = format("/%s-%s/JDBC_PASSWORD", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

data "aws_ssm_parameter" "jdbc_password" {
  name = aws_ssm_parameter.jdbc_password.name
}


resource "aws_ssm_parameter" "weblogic_admin_username" {
  name  = format("/%s/%s/DEV_USERNAME", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

data "aws_ssm_parameter" "delius_core_frontend_env_var_dev_username" {
  name = aws_ssm_parameter.weblogic_admin_username.name
}

resource "aws_ssm_parameter" "weblogic_admin_password" {
  name  = format("/%s/%s/DEV_PASSWORD", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

data "aws_ssm_parameter" "delius_core_frontend_env_var_dev_password" {
  name = aws_ssm_parameter.weblogic_admin_password.name
}

locals {
  weblogic_secrets = [
    "ADMIN_PASSWORD",
    "ANALYTICS_TAG",
    "API_CLIENT_SECRET",
    "APPLICATIONINSIGHTS_CONNECTION_STRING",
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",

    "JDBC_PASSWORD",

    "LDAP_CREDENTIAL",

    "MERGE_SECRET",

    "NOTIFICATION_API_KEY",

    "OAUTH_CLIENT_SECRET",

    "PDFCREATION_SECRET",

    "TOPIC_ARN",

    "USERMANAGEMENT_SECRET"
  ]
}

module "weblogic_ssm" {
  source           = "../helpers/ssm_params"
  application_name = "weblogic"
  environment_name = "${var.account_info.application_name}-${var.env_name}"
  params_plain     = var.delius_microservice_configs.weblogic_params
  params_secure    = local.weblogic_secrets
}

data "aws_ssm_parameter" "weblogic_ssm" {
  for_each = var.delius_microservice_configs.weblogic_params
  name     = "/${var.account_info.application_name}-${var.env_name}/weblogic/${each.key}"

  depends_on = [module.weblogic_ssm] # ensure module runs first before reading params.
}

