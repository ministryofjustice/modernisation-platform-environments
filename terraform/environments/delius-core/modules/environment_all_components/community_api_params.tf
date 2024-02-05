resource "aws_ssm_parameter" "delius_core_community_api_env_var_jdbc_url" {
  name  = format("/%s-%s/JDBC_URL", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = format("jdbc:oracle:thin:@//INITIAL_HOSTNAME_OVERRIDEN:INITIAL_PORT_OVERRIDDEN/%s", var.community_api.db_name)
  tags  = local.tags
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "delius_core_community_api_env_var_jdbc_password" {
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