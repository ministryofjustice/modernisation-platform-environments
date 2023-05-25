#### This file can be used to store data specific to the member account ####

data "aws_secretsmanager_secret" "ldap_credential" {
  name = "${local.app_name}-openldap-bind-password"
}
