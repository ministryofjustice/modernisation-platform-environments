
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
  weblogic_ssm = {
    vars = [
      "API_CLIENT_ID",
      "AWS_REGION",

      "BREACH_NOTICE_API_URL",
      "BREACH_NOTICE_UI_URL_FORMAT",

      "COOKIE_SECURE",

      "DELIUS_API_URL",
      "DMS_HOST",
      "DMS_OFFICE_URI_HOST",
      "DMS_OFFICE_URI_PORT",
      "DMS_PORT",
      "DMS_PROTOCOL",

      "EIS_USER_CONTEXT",
      "ELASTICSEARCH_URL",

      "GDPR_URL",

      "JDBC_CONNECTION_POOL_MAX_CAPACITY",
      "JDBC_CONNECTION_POOL_MIN_CAPACITY",
      "JDBC_URL",
      "JDBC_USERNAME",

      "LDAP_HOST",
      "LDAP_PRINCIPAL",
      "LOG_LEVEL_NDELIUS",

      "MERGE_API_URL",
      "MERGE_OAUTH_URL",
      "MERGE_URL",

      "NDELIUS_CLIENT_ID",

      "OAUTH_CALLBACK_URL",
      "OAUTH_CLIENT_ID",
      "OAUTH_DEFAULT_SCOPE",
      "OAUTH_LOGIN_ENABLED",
      "OAUTH_LOGIN_NAME",
      "OAUTH_TOKEN_VERIFICATION_URL",
      "OAUTH_URL",
      "OFFENDER_SEARCH_API_URL",

      "PASSWORD_RESET_URL",
      "PDFCREATION_TEMPLATES",
      "PDFCREATION_URL",
      "PREPARE_CASE_FOR_SENTENCE_URL",
      "PSR_SERVICE_URL",

      "TRAINING_MODE_APP_NAME",
      "TZ",

      "USER_CONTEXT",
      "USER_MEM_ARGS",
      "USERMANAGEMENT_URL"
    ]
    secrets = [
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
}

module "weblogic_ssm" {
  source           = "../helpers/ssm_params"
  application_name = "weblogic"
  environment_name = "${var.account_info.application_name}-${var.env_name}"
  params_plain     = local.weblogic_ssm.vars
  params_secure    = local.weblogic_ssm.secrets
}

data "aws_ssm_parameter" "weblogic_ssm" {
  for_each = toset(local.weblogic_ssm.vars)
  name     = "/${var.account_info.application_name}-${var.env_name}/weblogic/${each.key}"

  depends_on = [module.weblogic_ssm] # ensure module runs first before reading params.
}

