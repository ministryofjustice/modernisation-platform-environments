locals {
  fabric_tenant_id = data.aws_secretsmanager_secret_version.fabric_tenant_id.secret_string
}