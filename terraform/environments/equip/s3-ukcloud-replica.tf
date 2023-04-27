module "s3-bucket-ukcloud-replica" {
  count               = local.is-development ? 1 : 0
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.4.0"
  bucket_prefix       = "s3-bucket-ukcloud-replica"
  versioning_enabled  = false
  replication_enabled = false
  # The following providers configuration will not be used because 'replication_enabled' is false
  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "tmp"
      enabled = "Enabled"
      prefix  = "/tmp"

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
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

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  count  = local.is-development ? 1 : 0
  bucket = module.s3-bucket-ukcloud-replica[0].bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account[0].json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  count = local.is-development ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      module.s3-bucket-ukcloud-replica[0].bucket.arn,
      "${module.s3-bucket-ukcloud-replica[0].bucket.arn}/*"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["equip-production"]}:root"
      ]
    }
  }
}

resource "aws_iam_policy" "read_list_s3_access_policy" {
  count = local.is-development ? 1 : 0
  name  = "read_list_s3_access_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowUserToSeeBucketListInTheConsole",
        "Action" : ["s3:ListAllMyBuckets", "s3:GetBucketLocation"],
        "Effect" : "Allow",
        "Resource" : ["arn:aws:s3:::*"]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:Get*",
          "s3:List*"
        ],
        "Resource" : [
          module.s3-bucket-ukcloud-replica[0].bucket.arn,
          "${module.s3-bucket-ukcloud-replica[0].bucket.arn}/*"
        ]
      }
    ]
  })
}
