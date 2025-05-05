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
    resources = [module.cica_dms_ingress_bucket.s3_bucket_arn]
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
    resources = ["${module.cica_dms_ingress_bucket.s3_bucket_arn}/*"]
  }
  statement {
    sid    = "SourceBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [module.s3_cica_dms_ingress_kms.key_arn]
  }
  statement {
    sid    = "DestinationBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["arn:aws:kms:eu-west-2:593291632749:key/8894655b-e02c-46d1-aaa0-c219b31eefb1"]
  }
}

module "production_replication_cica_dms_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.54.1"

  name_prefix = "cica-dms-ingress-replication"

  policy = data.aws_iam_policy_document.production_cica_dms_replication.json
}

data "aws_iam_policy_document" "tariff_eventbridge_dms_full_load_task_policy" {
  statement {
    sid       = "AllowDmsTaskAccess"
    effect    = "Allow"
    actions   = ["dms:StartReplicationTask"]
    resources = [module.cica_dms_tariff_dms_implementation.dms_full_load_task_arn]
  }
}

module "tariff_eventbridge_dms_full_load_task_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.54.1"

  name_prefix = "tariff-cica-dms-eventbridge-full-load-task"

  policy = data.aws_iam_policy_document.tariff_eventbridge_dms_full_load_task_policy.json
}

data "aws_iam_policy_document" "tempus_eventbridge_dms_full_load_task_policy" {
  statement {
    sid       = "AllowDmsTaskAccess"
    effect    = "Allow"
    actions   = ["dms:StartReplicationTask"]
    resources = [for tempus_module in module.cica_dms_tempus_dms_implementation : tempus_module.dms_full_load_task_arn]
  }
}

module "tempus_eventbridge_dms_full_load_task_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.54.1"

  name_prefix = "tempus-cica-dms-eventbridge-full-load-task"

  policy = data.aws_iam_policy_document.tempus_eventbridge_dms_full_load_task_policy.json
}
