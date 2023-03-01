
module "s3-bucket" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix       = "s3-bucket"
  replication_enabled = false
  custom_kms_key      = module.environment.kms_keys["general"].arn

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags
}

module "nomis-db-backup-bucket" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix       = "nomis-db-backup-bucket"
  replication_enabled = false
  custom_kms_key      = module.environment.kms_keys["general"].arn

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "Enabled"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags

}

data "aws_iam_policy_document" "cross-account-s3" {
  statement {
    sid = "cross-account-s3-access-for-image-builder"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket"
    ]

    resources = ["${module.nomis-image-builder-bucket.bucket.arn}/*",
    module.nomis-image-builder-bucket.bucket.arn, ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["nomis-development"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["nomis-test"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["nomis-preproduction"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["nomis-production"]}:root"
      ]
    }
  }
}

module "nomis-image-builder-bucket" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix       = "ec2-image-builder-nomis"
  replication_enabled = false
  custom_kms_key      = module.environment.kms_keys["general"].arn

  bucket_policy = [data.aws_iam_policy_document.cross-account-s3.json]

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "Enabled"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags
}

#  Audit Archive dumps bucket
data "aws_iam_policy_document" "nomis-all-environments-access" {
  statement {
    sid = "all-nomis-environments-access-for-archiving"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket"

    ]

    resources = ["${module.nomis-audit-archives.bucket.arn}/*",
    module.nomis-audit-archives.bucket.arn, ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["nomis-development"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["nomis-test"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["nomis-preproduction"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["nomis-production"]}:root"
      ]
    }
  }
}

module "nomis-audit-archives" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.3.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix       = "nomis-audit-archives"
  replication_enabled = false
  custom_kms_key      = module.environment.kms_keys["general"].arn

  bucket_policy = [data.aws_iam_policy_document.nomis-all-environments-access.json]

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "Enabled"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags

}
