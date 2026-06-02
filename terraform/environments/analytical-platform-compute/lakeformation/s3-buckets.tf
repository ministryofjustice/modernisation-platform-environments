data "aws_iam_policy_document" "athena_query_results_policy_eu_west_2" {
  #checkov:skip=CKV_AWS_356:resource "*" limited by condition
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::mojap-compute-${local.environment}-athena-query-results-eu-west-2/*",
      "arn:aws:s3:::mojap-compute-${local.environment}-athena-query-results-eu-west-2"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

module "mojap_compute_athena_query_results_bucket_eu_west_2" {

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=af0286ff37a66c2b79faf360e6e2663744b8e5b5" # v5.13.0


  bucket = "mojap-compute-${local.environment}-athena-query-results-eu-west-2"

  force_destroy = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.athena_query_results_policy_eu_west_2.json

  object_lock_enabled = false

  versioning = {
    status = "Disabled"
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.mojap_compute_athena_s3_kms_eu_west_2.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = merge(
    local.tags,
    { "backup" = "false" }
  )
}
