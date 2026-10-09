# Microsoft Fabric integration: OIDC trust, IAM role, and curated S3 bucket
# exposed to Microsoft Fabric via OneLake S3 shortcuts.

module "fabric_oidc_provider" {
  count  = local.fabric_oidc_enabled ? 1 : 0
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/fabric-oidc-provider?ref=f1ac82228814d2fbdaf7d2d376f4d1531a0d78bf"

  tenant_id          = local.fabric_tenant_id
  oidc_provider_name = "fabric-s3-access"
}

# Curated S3 bucket exposed to Microsoft Fabric via OneLake shortcuts.
# TODO: Use KMS key for encryption.
module "fabric_curated_bucket" {
  count  = local.fabric_curated_bucket_enabled ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=ce9c0c07489e393ce80441aed0fd5bf7798956a3"

  bucket_prefix      = "laa-data-factory-curated"
  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  sse_algorithm = "AES256"

  tags = local.tags
}

module "fabric_iam_role" {
  count  = local.fabric_oidc_enabled ? 1 : 0
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/fabric-iam-role?ref=f1ac82228814d2fbdaf7d2d376f4d1531a0d78bf"

  object_id                          = local.fabric_enterprise_app_object_id
  oidc_provider_arn                  = module.fabric_oidc_provider[0].arn
  oidc_provider_condition_key_prefix = module.fabric_oidc_provider[0].condition_key_prefix
  audience                           = module.fabric_oidc_provider[0].client_id

  bucket_arn = (
    local.environment == "development"
    ? module.fabric_curated_bucket[0].bucket.arn
    : "arn:aws:s3:::laa-data-factory-processedraw-766696030771-eu-west-2-an"
  )
  role_name        = "fabric-s3-access"
  role_policy_name = "fabric-s3-read-policy"
}
