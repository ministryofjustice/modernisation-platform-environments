
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
      "PSR_SERVICE_URL",
      "TZ",
      "PDFCREATION_URL",
      "OFFENDER_SEARCH_API_URL",
      "DMS_OFFICE_URI_PORT",
      "MERGE_URL",
      "OAUTH_TOKEN_VERIFICATION_URL",
      "API_CLIENT_ID",
      "DMS_PROTOCOL",
      "JDBC_CONNECTION_POOL_MIN_CAPACITY",
      "PDFCREATION_TEMPLATES",
      "DMS_HOST",
      "COOKIE_SECURE",
      "USERMANAGEMENT_URL",
      "DELIUS_API_URL",
      "OAUTH_DEFAULT_SCOPE",
      "GDPR_URL",
      "AWS_REGION",
      "OAUTH_LOGIN_ENABLED",
      "DMS_OFFICE_URI_HOST",
      "JDBC_CONNECTION_POOL_MAX_CAPACITY",
      "DMS_PORT",
      "OAUTH_LOGIN_NAME",
      "JDBC_USERNAME",
      "USER_MEM_ARGS",
      "NDELIUS_CLIENT_ID",
      "JDBC_URL",
      "USER_CONTEXT",
      "OAUTH_URL",
      "PASSWORD_RESET_URL",
      "LOG_LEVEL_NDELIUS",
      "LDAP_HOST",
      "MERGE_API_URL",
      "ELASTICSEARCH_URL",
      "OAUTH_CLIENT_ID",
      "LDAP_PRINCIPAL",
      "OAUTH_CALLBACK_URL",
      "EIS_USER_CONTEXT",
      "MERGE_OAUTH_URL"
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
  environment_name = var.env_name
  params_list = concat(local.weblogic_ssm.vars, local.weblogic_ssm.secrets)

}

