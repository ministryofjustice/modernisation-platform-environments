data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "shared" {
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}"
  }
}

data "aws_subnets" "shared-data" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data*"
  }
}

data "aws_subnet" "private_subnet_a" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "private_subnet_b" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}b"
  }
}

data "aws_subnet" "private_subnet_c" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}c"
  }
}

data "aws_subnet" "public_subnet_a" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "public_subnet_b" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public-${data.aws_region.current.name}b"
  }
}

data "aws_subnet" "public_subnet_c" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public-${data.aws_region.current.name}c"
  }
}

data "aws_subnet" "data_subnet_a" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "data_subnet_b" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data-${data.aws_region.current.name}b"
  }
}

data "aws_subnet" "data_subnet_c" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data-${data.aws_region.current.name}c"
  }
}

data "aws_route53_zone" "external" {
  provider = aws.core-vpc

  name         = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

data "aws_route53_zone" "inner" {
  provider = aws.core-vpc

  name         = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.internal."
  private_zone = true
}

data "aws_route53_zone" "network-services" {
  provider = aws.core-network-services

  name         = "modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

data "aws_route53_zone" "application-zone" {
  provider = aws.core-network-services

  name         = "equip.service.justice.gov.uk."
  private_zone = false
}

data "aws_subnets" "shared-public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public*"
  }
}

data "terraform_remote_state" "core_network_services" {
  backend = "s3"
  config = {
    acl     = "bucket-owner-full-control"
    bucket  = "modernisation-platform-terraform-state"
    key     = "environments/accounts/core-network-services/core-network-services-production/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = "true"
  }
}

data "aws_iam_policy_document" "kms_policy" {
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
  }
}