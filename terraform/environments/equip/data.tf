data "aws_route53_zone" "application-zone" {
  provider = aws.core-network-services

  name         = "equip.service.justice.gov.uk."
  private_zone = false
}

data "aws_iam_policy_document" "kms_policy" {
  # checkov:skip=CKV_AWS_109: "Key policy requires asterisk resource"
  # checkov:skip=CKV_AWS_111: "Key policy requires asterisk resource"
  # checkov:skip=CKV_AWS_356: "Key policy requires asterisk resource"

  count = local.is-development ? 1 : 0
  statement {
    sid     = "Enable IAM User Permissions"
    actions = ["kms:*"]
    principals {
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.current.id)]
      type        = "AWS"
    }
    resources = ["*"]
  }

  statement {
    sid = "Allow access from remote account"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    principals {
      identifiers = [format("arn:aws:iam::%s:role/ModernisationPlatformAccess", local.environment_management.account_ids["equip-production"])]
      type        = "AWS"
    }
    resources = ["*"]
  }

  statement {
    sid = "Allow use of the key"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      identifiers = [format("arn:aws:iam::%s:root", local.environment_management.account_ids[format("%s-production", local.application_name)])]
      type        = "AWS"
    }
    resources = ["*"]
  }

  statement {
    sid = "Allow attachment of persistent resources"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    principals {
      identifiers = [format("arn:aws:iam::%s:root", local.environment_management.account_ids[format("%s-production", local.application_name)])]
      type        = "AWS"
    }
    condition {
      test     = "Bool"
      values   = ["true"]
      variable = "kms:GrantIsForAWSResource"
    }
    resources = ["*"]
  }
}

# Data source to fetch VPC from eucs-appstream account (only for development and production environments)
data "aws_vpc" "eucs_appstream" {
  provider = aws.eucs-appstream
  count    = local.is-development || local.is-production ? 1 : 0

  filter {
    name   = "tag:Name"
    values = ["hmpps-${local.environment}"]
  }
}

# Data source to fetch private subnets from eucs-appstream VPC
data "aws_subnets" "eucs_appstream_private" {
  provider = aws.eucs-appstream
  count    = local.is-development || local.is-production ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eucs_appstream[0].id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# Data source to fetch subnet details including CIDR blocks
data "aws_subnet" "eucs_appstream_private_details" {
  provider = aws.eucs-appstream
  for_each = local.is-development || local.is-production ? toset(data.aws_subnets.eucs_appstream_private[0].ids) : toset([])

  id = each.value
}
