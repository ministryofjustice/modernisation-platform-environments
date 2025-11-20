terraform {
  required_providers {
    aws = {
      version = "~>6.21, != 5.86.0"
      source  = "hashicorp/aws"
    }
  }
  required_version = "~> 1.0"
}

module "this-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${var.local_bucket_prefix}-export-${var.export_destination}-"
  versioning_enabled = false

  # to disable ACLs in preference of BucketOwnership controls as per https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/ set:
  ownership_controls = "BucketOwnerEnforced"
  acl                = "private"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below variable and providers configuration is only relevant if 'replication_enabled' is set to true
  # replication_region                       = "eu-west-2"
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    # Leave this provider block in even if you are not using replication
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      expiration = {
        days = 7
      }
    }
  ]

  # Add IP restricted access if IP's specified
  bucket_policy_v2 = var.allowed_ips != null ? [
    {
      sid     = "AllowedIPs"
      effect  = "Deny"
      actions = ["s3:GetObject"]
      principals = {
        identifiers = ["*"]
        type        = "AWS"
      }
      conditions = [
        {
          test     = "NotIpAddress"
          variable = "aws:SourceIp"
          values   = var.allowed_ips
        }
      ]
    }
    ] : [
    {
      sid     = "AllowedIPs"
      effect  = "Deny"
      actions = ["s3:GetObject"]
      principals = {
        identifiers = ["*"]
        type        = "AWS"
      }
      conditions = []
    }
  ]

  tags = merge(
    var.local_tags,
    { export_destination = var.export_destination }
  )
}

#------------------------------------------------------------------------------
# Encrypt lambda 
#------------------------------------------------------------------------------
# TODO Add a lambda function that is triggered when files are added to bucket.
# This lambda would encrypt zip the file, generating a password and saving the
# password into secret manager as key: value -> filename: encryption password.
# Then the original file would be deleted and replaced with the encrypted zip.
