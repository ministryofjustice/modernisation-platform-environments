data "aws_secretsmanager_secret" "fabric_tenant_id" {
  name = "data-factory-laa-development/fabric-tenant-id"
}

data "aws_secretsmanager_secret_version" "fabric_tenant_id" {
  secret_id = data.aws_secretsmanager_secret.fabric_tenant_id.id
}