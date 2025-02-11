data "aws_iam_policy_document" "production_cica_dms_replication" {
  statement {
    sid    = "DestinationBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateTags",
      "s3:ReplicateDelete"
    ]
    resources = ["arn:aws:s3:::mojap-data-production-cica-dms-ingress-production/*"]
  }
  statement {
    sid    = "SourceBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = length(module.cica_dms_ingress_bucket) > 0 ? [module.cica_dms_ingress_bucket[0].s3_bucket_arn] : []
  }
  statement {
    sid    = "SourceBucketObjectPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = length(module.cica_dms_ingress_bucket) > 0 ? ["${module.cica_dms_ingress_bucket[0].s3_bucket_arn}/*"] : []
  }
  statement {
    sid    = "SourceBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = length(module.s3_cica_dms_ingress_kms) > 0 ? [module.s3_cica_dms_ingress_kms[0].key_arn] : []
  }
  statement {
    sid    = "DestinationBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["arn:aws:kms:eu-west-2:593291632749:key/mrk-27fd90a6ddbc463fb78b0a21592fa8a1"]
  }
}

module "production_replication_cica_dms_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.52.2"

  name_prefix = "cica-dms-ingress-replication"

  policy = data.aws_iam_policy_document.production_cica_dms_replication.json
}
