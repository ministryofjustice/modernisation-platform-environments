# tflint-ignore-file: terraform_required_version, terraform_required_providers

data "aws_iam_policy_document" "this" {
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
    resources = [var.landing_bucket_kms_key]
  }
  statement {
    sid     = "AllowS3ListBucket"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.landing_bucket}",
      "arn:aws:s3:::${var.landing_bucket}/${var.name}/*"
    ]
  }
  statement {
    sid    = "AllowS3LandingBucketObjectActions"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::${var.landing_bucket}/${var.name}/*"]
  }
}

module "policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.58.0"

  name_prefix = "transfer-user-${var.name}"

  policy = data.aws_iam_policy_document.this.json
}

module "role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.58.0"

  create_role = true

  role_name         = "transfer-user-${var.name}"
  role_requires_mfa = false

  trusted_role_services = ["transfer.amazonaws.com"]

  custom_role_policy_arns = [module.policy.arn]
}

resource "aws_transfer_user" "this" {
  server_id      = var.transfer_server
  user_name      = var.name
  role           = module.role.iam_role_arn
  home_directory = "/${var.landing_bucket}/${var.name}"
}

resource "aws_transfer_ssh_key" "this" {
  server_id = var.transfer_server
  user_name = aws_transfer_user.this.user_name
  body      = var.ssh_key
}

# Create an aws_security_group per user as part of this module
resource "aws_security_group" "this" {
  description = "Security Group for Transfer Server User ${var.name}"
  name        = "transfer-server-${var.name}"
  vpc_id      = var.isolated_vpc_id
  # tags        = local.tags # Not picking this up
}

# resource "aws_security_group_rule" "this" {
#   description       = var.name
#   type              = "ingress"
#   from_port         = 2222
#   to_port           = 2222
#   protocol          = "tcp"
#   cidr_blocks       = var.cidr_blocks
#   security_group_id = var.transfer_server_security_group
# }

# Replace aws_security_group_rule with recommended resource
resource "aws_vpc_security_group_ingress_rule" "this" {
  description       = var.name
  from_port         = 2222
  ip_protocol       = "tcp"
  to_port           = 2222
  security_group_id = aws_security_group.this.id
  # security_group_id = var.transfer_server_security_group
  for_each          = var.cidr_blocks
  cidr_ipv4         = each.value
}

resource "aws_secretsmanager_secret" "this" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret

  for_each = toset(["technical-contact", "data-contact", "target-bucket", "slack-channel"])

  name       = "ingestion/sftp/${var.name}/${each.key}"
  kms_key_id = var.supplier_data_kms_key
}
