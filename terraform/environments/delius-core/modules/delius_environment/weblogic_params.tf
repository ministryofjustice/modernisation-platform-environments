
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


# # # # # # # # # #
# container vars  #
# # # # # # # # # #

resource "aws_ssm_parameter" "weblogic_psr_service_url" {
  name  = format("/%s-%s/PSR_SERVICE_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_tz" {
  name  = format("/%s-%s/TZ", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_pdfcreation_url" {
  name  = format("/%s-%s/PDFCREATION_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_offender_search_api_url" {
  name  = format("/%s-%s/OFFENDER_SEARCH_API_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_dms_office_uri_port" {
  name  = format("/%s-%s/DMS_OFFICE_URI_PORT", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_merge_url" {
  name  = format("/%s-%s/MERGE_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_oauth_token_verification_url" {
  name  = format("/%s-%s/OAUTH_TOKEN_VERIFICATION_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_api_client_id" {
  name  = format("/%s-%s/API_CLIENT_ID", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_dms_protocol" {
  name  = format("/%s-%s/DMS_PROTOCOL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_jdbc_connection_pool_min_capacity" {
  name  = format("/%s-%s/JDBC_CONNECTION_POOL_MIN_CAPACITY", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_pdfcreation_templates" {
  name  = format("/%s-%s/PDFCREATION_TEMPLATES", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_dms_host" {
  name  = format("/%s-%s/DMS_HOST", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_cookie_secure" {
  name  = format("/%s-%s/COOKIE_SECURE", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_usermanagement_url" {
  name  = format("/%s-%s/USERMANAGEMENT_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_delius_api_url" {
  name  = format("/%s-%s/DELIUS_API_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_oauth_default_scope" {
  name  = format("/%s-%s/OAUTH_DEFAULT_SCOPE", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_gdpr_url" {
  name  = format("/%s-%s/GDPR_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_aws_region" {
  name  = format("/%s-%s/AWS_REGION", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_oauth_login_enabled" {
  name  = format("/%s-%s/OAUTH_LOGIN_ENABLED", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_dms_office_uri_host" {
  name  = format("/%s-%s/DMS_OFFICE_URI_HOST", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_jdbc_connection_pool_max_capacity" {
  name  = format("/%s-%s/JDBC_CONNECTION_POOL_MAX_CAPACITY", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_dms_port" {
  name  = format("/%s-%s/DMS_PORT", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_oauth_login_name" {
  name  = format("/%s-%s/OAUTH_LOGIN_NAME", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_jdbc_username" {
  name  = format("/%s-%s/JDBC_USERNAME", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_user_mem_args" {
  name  = format("/%s-%s/USER_MEM_ARGS", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_ndelius_client_id" {
  name  = format("/%s-%s/NDELIUS_CLIENT_ID", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_jdbc_url" {
  name  = format("/%s-%s/JDBC_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_user_context" {
  name  = format("/%s-%s/USER_CONTEXT", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_oauth_url" {
  name  = format("/%s-%s/OAUTH_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_password_reset_url" {
  name  = format("/%s-%s/PASSWORD_RESET_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_log_level_ndelius" {
  name  = format("/%s-%s/LOG_LEVEL_NDELIUS", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_ldap_host" {
  name  = format("/%s-%s/LDAP_HOST", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_merge_api_url" {
  name  = format("/%s-%s/MERGE_API_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_elasticsearch_url" {
  name  = format("/%s-%s/ELASTICSEARCH_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_oauth_client_id" {
  name  = format("/%s-%s/OAUTH_CLIENT_ID", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_ldap_principal" {
  name  = format("/%s-%s/LDAP_PRINCIPAL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_oauth_callback_url" {
  name  = format("/%s-%s/OAUTH_CALLBACK_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_eis_user_context" {
  name  = format("/%s-%s/EIS_USER_CONTEXT", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_merge_oauth_url" {
  name  = format("/%s-%s/MERGE_OAUTH_URL", var.account_info.application_name, var.env_name)
  type  = "String"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

# # # # # # # # # # # 
# container secrets #
# # # # # # # # # # # 

# duplicate at the moment

# resource "aws_ssm_parameter" "weblogic_admin_password" {
#   name  = format("/%s-%s/ADMIN_PASSWORD", var.account_info.application_name, var.env_name)
#   type  = "SecureString"
#   value = "INITIAL_VALUE_OVERRIDDEN"
#   tags  = local.tags
#   lifecycle { ignore_changes = [ value ] }
# }

resource "aws_ssm_parameter" "weblogic_analytics_tag" {
  name  = format("/%s-%s/ANALYTICS_TAG", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_api_client_secret" {
  name  = format("/%s-%s/API_CLIENT_SECRET", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_applicationinsights_connection_string" {
  name  = format("/%s-%s/APPLICATIONINSIGHTS_CONNECTION_STRING", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_aws_access_key_id" {
  name  = format("/%s-%s/AWS_ACCESS_KEY_ID", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_aws_secret_access_key" {
  name  = format("/%s-%s/AWS_SECRET_ACCESS_KEY", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_jdbc_password" {
  name  = format("/%s-%s/JDBC_PASSWORD", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_ldap_credential" {
  name  = format("/%s-%s/LDAP_CREDENTIAL", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_merge_secret" {
  name  = format("/%s-%s/MERGE_SECRET", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_oauth_client_secret" {
  name  = format("/%s-%s/OAUTH_CLIENT_SECRET", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_pdfcreation_secret" {
  name  = format("/%s-%s/PDFCREATION_SECRET", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_topic_arn" {
  name  = format("/%s-%s/TOPIC_ARN", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}

resource "aws_ssm_parameter" "weblogic_usermanagement_secret" {
  name  = format("/%s-%s/USERMANAGEMENT_SECRET", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle { ignore_changes = [ value ] }
}


