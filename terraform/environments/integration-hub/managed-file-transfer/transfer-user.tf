data "aws_iam_policy_document" "transfer_user" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
    ]
    resources = [module.kms_s3_bucket["unscanned"].key_arn]
  }
  statement {
    sid     = "AllowS3ListBucket"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      module.s3_bucket["unscanned"].s3_bucket_arn,
      "${module.s3_bucket["unscanned"].s3_bucket_arn}/*"
    ]
  }
  statement {
    sid    = "AllowS3LandingBucketObjectActions"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = ["${module.s3_bucket["unscanned"].s3_bucket_arn}/*"]
  }
}

module "transfer_user_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.0"

  name        = "${local.application_name}-transfer-user-policy"
  description = "AWS Transfer User policy"
  path        = "/"

  policy = data.aws_iam_policy_document.transfer_user.json

  tags = local.tags
}

module "transfer_user_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"

  name            = "${local.application_name}-transfer-user-role"
  description     = "AWS Transfer User role"
  use_name_prefix = true

  trust_policy_permissions = {
    AllowTransferService = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["transfer.amazonaws.com"]
      }]
    }
  }

  policies = {
    transfer_user_policy = module.transfer_user_policy.arn
  }
}

# POC user based on my GitHub username
resource "aws_transfer_user" "dms1981" {
  role      = module.transfer_user_role.arn
  server_id = aws_transfer_server.this.id
  user_name = "dms1981"
}

resource "aws_transfer_ssh_key" "dms1981" {
  body      = "value"
  server_id = aws_transfer_server.this.id
  user_name = aws_transfer_user.dms1981.user_name

}