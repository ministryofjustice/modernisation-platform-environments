module "artifacts-s3" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=c8889e65f4d8a3d53d2cbd93b7be714e990020b7" # v10.2.1

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix       = "${local.application_name}-build-artifacts"
  replication_enabled = false
  versioning_enabled  = true
  force_destroy       = true
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
        days = 31
      }

      noncurrent_version_expiration = {
        days = 31
      }
    }
  ]

  bucket_policy = [jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "DenyInsecureTransport",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          module.artifacts-s3.bucket.arn,
          "${module.artifacts-s3.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        "Sid" : "EnforceTLSv12orHigher",
        "Action" : "s3:*",
        "Effect" : "Deny",
        "Resource" : [
          module.artifacts-s3.bucket.arn,
          "${module.artifacts-s3.bucket.arn}/*"
        ],
        "Condition" : {
          "NumericLessThan" : {
            "s3:TlsVersion" : "1.2"
          }
        },
        "Principal" : {
          "AWS" : "*"
        }
      }
    ]
  })]

  tags = local.tags
}
