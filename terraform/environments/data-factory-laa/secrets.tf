resource "aws_secretsmanager_secret" "fabric_tenant_id" {
  #checkov:skip=CKV_AWS_149: TODO: Only used for testing. Use CMK to encrypt after testing.
  #checkov:skip=CKV2_AWS_57: Automatic rotation not used for fabric
  name = "data-factory-laa-${local.environment}/fabric-tenant-id"
  tags = local.tags
}

resource "aws_secretsmanager_secret" "fabric_enterprise_app_object_id" {
  #checkov:skip=CKV_AWS_149: TODO: Only used for testing. Use CMK to encrypt after testing.
  #checkov:skip=CKV2_AWS_57: Automatic rotation not used for fabric
  name = "data-factory-laa-${local.environment}/fabric-enterprise-app-object-id"
  tags = local.tags
}
