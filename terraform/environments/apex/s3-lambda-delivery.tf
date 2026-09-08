# Shared S3 bucket for Lambda layer delivery
# Note: upload lambda_delivery/cloudwatch_sns_layer/layerV1.zip manually before first apply
# See: https://dsdmoj.atlassian.net/wiki/spaces/LDD/pages/5975606239/Build+Layered+Function+for+Lambda

module "s3-bucket-shared" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=c8889e65f4d8a3d53d2cbd93b7be714e990020b7" # v10.2.1

  bucket_name         = "${local.application_name}-${local.environment}-shared"
  versioning_enabled  = true
  replication_enabled = false
  replication_region  = "eu-west-2"
  sse_algorithm       = "AES256"
  custom_kms_key      = ""
  bucket_policy       = [aws_s3_bucket_policy.shared_bucket_policy.policy]

  providers = {
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

      abort_incomplete_multipart_upload_days = 7
    }
  ]

  tags = merge(local.tags,
    { Name = "${local.application_name}-${local.environment}-shared" }
  )
}

resource "aws_s3_bucket_policy" "shared_bucket_policy" {
  bucket = module.s3-bucket-shared.bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "DenyInsecureTransport",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : ["${module.s3-bucket-shared.bucket.arn}/*", "${module.s3-bucket-shared.bucket.arn}"],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        Sid    = "EnforceTLSv12orHigher",
        Effect = "Deny",
        Principal = {
          AWS = "*"
        },
        Action   = "s3:*",
        Resource = ["${module.s3-bucket-shared.bucket.arn}/*", "${module.s3-bucket-shared.bucket.arn}"],
        Condition = {
          NumericLessThan = {
            "s3:TlsVersion" = "1.2"
          }
        }
      }
    ]
  })
}

resource "aws_s3_object" "folder" {
  bucket = module.s3-bucket-shared.bucket.id
  for_each = {
    for index, name in local.lambda_folder_name :
    name => index == 0 ? "${name}/" : "lambda_delivery/${name}/"
  }

  key = each.value
}
