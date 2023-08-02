
##
# SSM Parameter Store for delius-core-frontend
##

resource "aws_ssm_parameter" "delius_core_frontend_env_var_jdbc_url" {
  name  = format("/%s/JCBC_URL", var.env_name)
  type  = "SecureString"
  value = format("jdbc:oracle:thin:@//INITIAL_HOSTNAME_OVERRIDEN:INITIAL_PORT_OVERRIDDEN/%s", var.weblogic_config.db_name)
  tags  = local.tags
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "delius_core_frontend_env_var_jdbc_password" {
  name  = format("/%s/JCBC_PASSWORD", var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "delius_core_frontend_env_var_test_mode" {
  name  = format("/%s/TEST_MODE", var.env_name)
  type  = "String"
  value = "true"
  tags  = local.tags
}

resource "aws_ssm_parameter" "delius_core_frontend_env_var_dev_username" {
  name  = format("/%s/DEV_USERNAME", var.env_name)
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
  name  = format("/%s/DEV_PASSWORD", var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

data "aws_ssm_parameter" "delius_core_frontend_env_var_jdbc_url" {
  name = aws_ssm_parameter.delius_core_frontend_env_var_jdbc_url.name
}

data "aws_ssm_parameter" "delius_core_frontend_env_var_jdbc_password" {
  name = aws_ssm_parameter.delius_core_frontend_env_var_jdbc_password.name
}

data "aws_ssm_parameter" "delius_core_frontend_env_var_test_mode" {
  name = aws_ssm_parameter.delius_core_frontend_env_var_test_mode.name
}

data "aws_ssm_parameter" "delius_core_frontend_env_var_dev_username" {
  name = aws_ssm_parameter.delius_core_frontend_env_var_dev_username.name
}

data "aws_ssm_parameter" "delius_core_frontend_env_var_dev_password" {
  name = aws_ssm_parameter.delius_core_frontend_env_var_dev_password.name
}


################
data "aws_ssm_parameter" "delius_core_frontend_env_var_ldap_host" {
  name = format("/%s/LDAP_HOST", var.env_name)
}

data "aws_ssm_parameter" "delius_core_frontend_env_var_ldap_port" {
  name = format("/%s/LDAP_PORT", var.env_name)
}

data "aws_ssm_parameter" "delius_core_frontend_env_var_ldap_principal" {
  name = format("/%s/LDAP_PRINCIPAL", var.env_name)
}

data "aws_ssm_parameter" "delius_core_frontend_env_var_user_context" {
  name = format("/%s/USER_CONTEXT", var.env_name)
}

data "aws_ssm_parameter" "delius_core_frontend_env_var_eis_user_context" {
  name = format("/%s/EIS_USER_CONTEXT", var.env_name)
}

resource "aws_secretsmanager_secret" "ldap_credential" {
  name = "${var.env_name}-openldap-bind-password"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "ldap_credential" {
  secret_id     = aws_secretsmanager_secret.ldap_credential.id
  secret_string = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

data "aws_secretsmanager_secret" "ldap_credential" {
  name = "${var.env_name}-openldap-bind-password"
}
