resource "aws_cur_report_definition" "cur_planetfm" {
  provider                   = aws.us-east-1
  report_name                = "planetfm-cur-report-definition"
  time_unit                  = "HOURLY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES", "SPLIT_COST_ALLOCATION_DATA"]
  s3_bucket                  = module.s3-bucket.bucket.id
  s3_region                  = "eu-west-2"
  additional_artifacts       = ["ATHENA"]
  report_versioning          = "OVERWRITE_REPORT" 
}

module "s3-bucket" {
    source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.1.0"

    bucket_prefix = "planetfm"
    versioning_enabled = false
    bucket_policy = [data.aws_iam_policy_document.cur_bucket_policy.json]
    force_destroy  = true
    replication_enabled = false

    tags = merge(local.tags, {
        Name = lower(format("cur-report-bucket-%s-%s", local.application_name, local.environment))
    })
}

data "aws_iam_policy_document" "cur_bucket_policy" {
    statement {
        sid       = "EnsureBucketOwnedByAccountForCURDelivery"
        effect    = "Allow"
        resources = [module.s3-bucket.bucket.arn]

        actions = [
        "s3:GetBucketAcl",
        "s3:GetBucketPolicy",
        ]

        condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values   = ["arn:aws:cur:us-east-1:${local.environment_management.account_ids[terraform.workspace]}:definition/*"]
        }

        condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = ["${local.environment_management.account_ids[terraform.workspace]}"]
        }

        principals {
        type        = "Service"
        identifiers = ["billingreports.amazonaws.com"]
        }
    }

    statement {
        sid       = "GrantAccessToDeliverCURFiles"
        effect    = "Allow"
        resources = ["${module.s3-bucket.bucket.arn}/*"]
        actions   = ["s3:PutObject"]

        condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values   = ["arn:aws:cur:us-east-1:${local.environment_management.account_ids[terraform.workspace]}:definition/*"]
        }

        condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = ["${local.environment_management.account_ids[terraform.workspace]}"]
        }

        principals {
        type        = "Service"
        identifiers = ["billingreports.amazonaws.com"]
        }
    }
}
