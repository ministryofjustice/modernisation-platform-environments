
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

resource "aws_ssm_parameter" "delius_core_frontend_env_var_jdbc_password" {
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

resource "aws_ssm_parameter" "delius_core_frontend_env_var_dev_username" {
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

resource "aws_ssm_parameter" "delius_core_frontend_env_var_dev_password" {
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


data "aws_ssm_parameter" "jdbc_url" {
  name = aws_ssm_parameter.jdbc_url.name
}

data "aws_ssm_parameter" "delius_core_frontend_env_var_jdbc_password" {
  name = aws_ssm_parameter.delius_core_frontend_env_var_jdbc_password.name
}


data "aws_ssm_parameter" "delius_core_frontend_env_var_dev_username" {
  name = aws_ssm_parameter.delius_core_frontend_env_var_dev_username.name
}

data "aws_ssm_parameter" "delius_core_frontend_env_var_dev_password" {
  name = aws_ssm_parameter.delius_core_frontend_env_var_dev_password.name
}