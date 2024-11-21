module "mlflow_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.2"

  bucket = "mojap-compute-${local.environment}-mlflow"

  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.mlflow_s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = local.tags
}

data "aws_iam_policy_document" "s3_server_access_logs_eu_west_2_policy" {
  #checkov:skip=CKV_AWS_356:resource "*" limited by condition
  statement {
    sid       = "S3ServerAccessLogsPolicy"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::mojap-compute-${local.environment}-logs-eu-west-2/*"]
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

module "mojap_compute_logs_bucket_eu_west_2" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.2"

  bucket = "mojap-compute-${local.environment}-logs-eu-west-2"

  force_destroy = false

  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_server_access_logs_eu_west_2_policy.json

  object_lock_enabled = false

  versioning = {
    status = "Disabled"
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.mojap_compute_logs_s3_kms_eu_west_2.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = merge(
    local.tags,
    { "backup" = "false" }
  )
}

data "aws_iam_policy_document" "s3_server_access_logs_eu_west_1_policy" {
  #checkov:skip=CKV_AWS_356:resource "*" limited by condition
  statement {
    sid       = "S3ServerAccessLogsPolicy"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::mojap-compute-${local.environment}-logs-eu-west-1/*"]
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

module "mojap_compute_logs_bucket_eu_west_1" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.2"

  providers = {
    aws = aws.analytical-platform-compute-eu-west-1
  }

  bucket = "mojap-compute-${local.environment}-logs-eu-west-1"

  force_destroy = false

  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_server_access_logs_eu_west_1_policy.json

  object_lock_enabled = false

  versioning = {
    status = "Disabled"
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.mojap_compute_logs_s3_kms_eu_west_1.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = merge(
    local.tags,
    { "backup" = "false" }
  )
}

moved {
  from = module.mojap_compute_logs_bucket.aws_s3_bucket.this[0]
  to   = module.mojap_compute_logs_bucket_eu_west_2.aws_s3_bucket.this[0]
}
moved {
  from = module.mojap_compute_logs_bucket.aws_s3_bucket_policy.this[0]
  to   = module.mojap_compute_logs_bucket_eu_west_2.aws_s3_bucket_policy.this[0]
}
moved {
  from = module.mojap_compute_logs_bucket.aws_s3_bucket_public_access_block.this[0]
  to   = module.mojap_compute_logs_bucket_eu_west_2.aws_s3_bucket_public_access_block.this[0]
}
moved {
  from = module.mojap_compute_logs_bucket.aws_s3_bucket_server_side_encryption_configuration.this[0]
  to   = module.mojap_compute_logs_bucket_eu_west_2.aws_s3_bucket_server_side_encryption_configuration.this[0]
}
moved {
  from = module.mojap_compute_logs_bucket.aws_s3_bucket_versioning.this[0]
  to   = module.mojap_compute_logs_bucket_eu_west_2.aws_s3_bucket_versioning.this[0]
}

moved {
  from = aws_iam_policy_document.s3_server_access_logs_policy
  to   = aws_iam_policy_document.s3_server_access_logs_eu_west_2_policy
}
