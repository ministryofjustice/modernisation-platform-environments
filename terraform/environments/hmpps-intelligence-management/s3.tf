#------------------------------------------------------------------------------
# S3 Bucket
#------------------------------------------------------------------------------
module "s3-bucket" { #tfsec:ignore:aws-s3-enable-versioning
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.3.0"

  bucket_prefix      = "mercury-dev"
  versioning_enabled = false
  bucket_policy      = [data.aws_iam_policy_document.bucket_policy.json]

  # Enable bucket to be destroyed when not empty
  force_destroy = true
  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  # replication_region = "eu-west-2"
  # replication_role_arn = module.s3-bucket-replication-role.role.arn
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    aws.bucket-replication = aws
  }

  tags = merge(local.tags,
    { Name = lower(format("s3-bucket-%s-%s-example", local.application_name, local.environment)) }
  )
}

data "aws_iam_policy_document" "bucket_policy" {

  statement {
    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::720459241262:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-developer_58965ce32623df8d"
      ]
    }

    actions = [
      "s3:GetObject",
      "s3.PutObject",
      "s3.ListBucket",
    ]

    resources = [
      module.s3-bucket.bucket.arn,
      "${module.s3-bucket.bucket.arn}/*",
    ]
  }
}