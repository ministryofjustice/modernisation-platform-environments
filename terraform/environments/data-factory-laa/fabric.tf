# Microsoft Fabric integration: OIDC trust, IAM role, and curated S3 bucket
# exposed to Microsoft Fabric via OneLake S3 shortcuts.

module "fabric_oidc_provider" {
  count  = local.fabric_oidc_enabled ? 1 : 0
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/fabric-oidc-provider?ref=f9867304610d6ff9604bf079aa56d3c2f4c49800"

  tenant_id          = local.fabric_tenant_id
  oidc_provider_name = "fabric-s3-access"
}

# Curated S3 bucket exposed to Microsoft Fabric via OneLake shortcuts.
# TODO: Use KMS key for encryption.
module "fabric_curated_bucket" {
  count  = local.fabric_oidc_enabled ? 1 : 0
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
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/fabric-iam-role?ref=f9867304610d6ff9604bf079aa56d3c2f4c49800"

  object_id                          = local.fabric_enterprise_app_object_id
  oidc_provider_arn                  = module.fabric_oidc_provider[0].arn
  oidc_provider_condition_key_prefix = module.fabric_oidc_provider[0].condition_key_prefix

  bucket_arn       = module.fabric_curated_bucket[0].bucket.arn
  role_name        = "fabric-s3-access"
  role_policy_name = "fabric-s3-read-policy"
}
