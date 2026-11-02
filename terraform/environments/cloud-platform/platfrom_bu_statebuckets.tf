locals {
  bu_accounts = jsondecode(
    file("${path.module}/accounts.json")
  ).accounts

  bu_live_accounts = {
    for account in local.bu_accounts :
    trimsuffix(
      replace(account, "container-platform-", ""),
      "-live"
    ) => {
      workspace = account
      account_id = local.environment_management.account_ids[account]
    }
    if endswith(account, "-live")
  }

  bu_state_bucket_names = {
    for bu, account in local.bu_live_accounts :
    bu => "${account.workspace}-tf-state-bucket"
  }
}



# -----------------------------------------------------------------------------
# AWS providers
#
# Each provider targets the live account for one BU.
# The role name follows the github-actions-apply role used in the MP workflow.
# -----------------------------------------------------------------------------

provider "aws" {
  alias  = "octo"
  region = "eu-west-2"

  allowed_account_ids = [
    local.bu_live_accounts["octo"].account_id
  ]

  assume_role {
    role_arn = "arn:aws:iam::${local.bu_live_accounts["octo"].account_id}:role/github-actions-apply"
  }
}

provider "aws" {
  alias  = "laa"
  region = "eu-west-2"

  allowed_account_ids = [
    local.bu_live_accounts["laa"].account_id
  ]

  assume_role {
    role_arn = "arn:aws:iam::${local.bu_live_accounts["laa"].account_id}:role/github-actions-apply"
  }
}

provider "aws" {
  alias  = "hmpps"
  region = "eu-west-2"

  allowed_account_ids = [
    local.bu_live_accounts["hmpps"].account_id
  ]

  assume_role {
    role_arn = "arn:aws:iam::${local.bu_live_accounts["hmpps"].account_id}:role/github-actions-apply"
  }
}

provider "aws" {
  alias  = "cd"
  region = "eu-west-2"

  allowed_account_ids = [
    local.bu_live_accounts["cd"].account_id
  ]

  assume_role {
    role_arn = "arn:aws:iam::${local.bu_live_accounts["cd"].account_id}:role/github-actions-apply"
  }
}

# -----------------------------------------------------------------------------
# TLS-only bucket policies
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "bu_state_bucket" {
  for_each = local.bu_live_accounts

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::${local.bu_state_bucket_names[each.key]}",
      "arn:aws:s3:::${local.bu_state_bucket_names[each.key]}/*"
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

  statement {
    sid    = "DenyInsecureTLS"
    effect = "Deny"
    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::${local.bu_state_bucket_names[each.key]}",
      "arn:aws:s3:::${local.bu_state_bucket_names[each.key]}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }
}

# -----------------------------------------------------------------------------
# BU Terraform state buckets
#
# One bucket per business unit, provisioned in that BU's live account.
# -----------------------------------------------------------------------------

module "octo_state_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  providers = {
    aws = aws.octo
  }

  bucket_name   = local.bu_state_bucket_names["octo"]
  bucket_policy = [data.aws_iam_policy_document.bu_state_bucket["octo"].json]
  sse_algorithm               = "aws:kms"
  custom_kms_key              = aws_kms_key.octo_state.arn
  enforce_kms_request_headers = false
  replication_enabled         = false

  tags = merge(local.tags, {
    BusinessUnit = "octo"
    Purpose      = "Terraform state"
  })

  
}

module "laa_state_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  providers = {
    aws = aws.laa
  }

  bucket_name   = local.bu_state_bucket_names["laa"]
  bucket_policy = [data.aws_iam_policy_document.bu_state_bucket["laa"].json]

  sse_algorithm               = "aws:kms"
  custom_kms_key              = aws_kms_key.laa_state.arn
  enforce_kms_request_headers = false
  replication_enabled         = false

  tags = merge(local.tags, {
    BusinessUnit = "laa"
    Purpose      = "Terraform state"
  })
}

module "hmpps_state_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  providers = {
    aws = aws.hmpps
  }

  bucket_name   = local.bu_state_bucket_names["hmpps"]
  bucket_policy = [data.aws_iam_policy_document.bu_state_bucket["hmpps"].json]

  sse_algorithm               = "aws:kms"
  custom_kms_key              = aws_kms_key.hmpps_state.arn
  enforce_kms_request_headers = false
  replication_enabled         = false

  tags = merge(local.tags, {
    BusinessUnit = "hmpps"
    Purpose      = "Terraform state"
  })
}

module "cd_state_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  providers = {
    aws = aws.cd
  }

  bucket_name   = local.bu_state_bucket_names["cd"]
  bucket_policy = [data.aws_iam_policy_document.bu_state_bucket["cd"].json]

  sse_algorithm               = "aws:kms"
  custom_kms_key              = aws_kms_key.cd_state.arn
  enforce_kms_request_headers = false
  replication_enabled           = false

  tags = merge(local.tags, {
    BusinessUnit = "cd"
    Purpose      = "Terraform state"
  })
}

resource "aws_kms_key" "octo_state" {
  provider = aws.octo

  description             = "KMS key for OCTO Terraform state bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_key" "laa_state" {
  provider = aws.laa

  description             = "KMS key for LAA Terraform state bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_key" "hmpps_state" {
  provider = aws.hmpps

  description             = "KMS key for HMPPS Terraform state bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_key" "cd_state" {
  provider = aws.cd

  description             = "KMS key for Central Digital Terraform state bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

# -----------------------------------------------------------------------------
# Bucket controls
#
# Versioning and public access blocking are managed in a dedicated module so
# the bucket module only owns the bucket and its KMS configuration.
# -----------------------------------------------------------------------------

module "octo_state_controls" {
  source = "../../modules/state_bucket_controls"

  providers = {
    aws = aws.octo
  }

  bucket_id = module.octo_state_bucket.bucket.id
}

module "laa_state_controls" {
  source = "../../modules/state_bucket_controls"

  providers = {
    aws = aws.laa
  }

  bucket_id = module.laa_state_bucket.bucket.id
}

module "hmpps_state_controls" {
  source = "../../modules/state_bucket_controls"

  providers = {
    aws = aws.hmpps
  }

  bucket_id = module.hmpps_state_bucket.bucket.id
}

module "cd_state_controls" {
  source = "../../modules/state_bucket_controls"

  providers = {
    aws = aws.cd
  }

  bucket_id = module.cd_state_bucket.bucket.id
}