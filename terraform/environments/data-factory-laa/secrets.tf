resource "aws_secretsmanager_secret" "fabric_tenant_id" {
  name = "data-factory-laa-${local.environment}/fabric-tenant-id"
  tags = local.tags
}

resource "aws_secretsmanager_secret" "fabric_enterprise_app_object_id" {
  name = "data-factory-laa-${local.environment}/fabric-enterprise-app-object-id"
  tags = local.tags
}