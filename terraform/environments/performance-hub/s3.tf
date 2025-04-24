#------------------------------------------------------------------------------
# S3 Bucket for file uploads and other user-generated content
# (note this code predates the Modernisation Platform S3 module used below
# for "ap_landing_bucket")
#------------------------------------------------------------------------------
#tfsec:ignore:AWS002 tfsec:ignore:AWS098
resource "aws_s3_bucket" "upload_files" {
  #checkov:skip=CKV_AWS_18
  #checkov:skip=CKV_AWS_144
  #checkov:skip=CKV2_AWS_6
  bucket = "${local.application_name}-uploads-${local.environment}"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-uploads"
    }
  )
}

resource "aws_s3_bucket_acl" "upload_files" {
  bucket = aws_s3_bucket.upload_files.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "upload_files" {
  bucket = aws_s3_bucket.upload_files.id
  rule {
    id     = "tf-s3-lifecycle"
    status = "Enabled"
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "upload_files" {
  bucket = aws_s3_bucket.upload_files.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_versioning" "upload_files" {
  bucket = aws_s3_bucket.upload_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

## was a "grant all" policy attached directy to cicduser
# resource "aws_s3_bucket_policy" "upload_files_policy" {
#   bucket = aws_s3_bucket.upload_files.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Id      = "upload_bucket_policy"
#     Statement = [
#       {
#         Effect    = "Allow"
#         actions = ["s3:GetObject","s3:PutObject","s3:ListBucket"]
#         Resource = [
#           aws_s3_bucket.upload_files.arn,
#           "${aws_s3_bucket.upload_files.arn}/*",
#         ]
#       },
#     ]
#   })
# }

resource "aws_iam_role" "s3_uploads_role" {
  name               = "${local.application_name}-s3-uploads-role"
  assume_role_policy = data.aws_iam_policy_document.s3-access-policy.json
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-s3-uploads-role"
    }
  )
}

data "aws_iam_policy_document" "s3-access-policy" {
  version = "2012-10-17"
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "rds.amazonaws.com",
        "ec2.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "s3-uploads-policy" {
  name   = "${local.application_name}-s3-uploads-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "s3:*"
      ],
      "Resource": [
          "${aws_s3_bucket.upload_files.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.upload_files.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetEncryptionConfiguration"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
      "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_uploads_attachment" {
  role       = aws_iam_role.s3_uploads_role.name
  policy_arn = aws_iam_policy.s3-uploads-policy.arn
}

#-------------------------------------------------------------------------------------------------
# S3 "landing" bucket for AP data transfer 
# AP pipelines write to this bucket and the Performance Hub reads files from here. It doesn't need
# complex retention versioning or replication since files are removed from this bucket once imported.
#-------------------------------------------------------------------------------------------------

module "ap_landing_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.1.0"

  bucket_name        = "${local.application_name}-land-${local.environment}"
  ownership_controls = "BucketOwnerEnforced"

  versioning_enabled  = false
  replication_enabled = false

  bucket_policy = [data.aws_iam_policy_document.allow_ap_write_to_landing.json]

  providers = {
    # Leave this provider block in even if you are not using replication
    aws.bucket-replication = aws
  }

  custom_kms_key = aws_kms_key.s3.arn

  lifecycle_rule = [
    {
      id      = "tf-s3-lifecycle-landing"
      enabled = "Enabled"

      expiration = {
        days = 30
      }
    }
  ]

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ap-landing-bucket"
    }
  )
}

# AP Airflow jobs are expecting certain folders to exist
resource "aws_s3_object" "prison_incidents" {
  bucket = module.ap_landing_bucket.bucket.id
  key    = "prison_incidents/"
}

resource "aws_s3_object" "prison_performance" {
  bucket = module.ap_landing_bucket.bucket.id
  key    = "prison_performance/"
}

data "aws_iam_policy_document" "allow_ap_write_to_landing" {
  # See also: https://github.com/moj-analytical-services/data-engineering-exports/tree/main/push_datasets
  statement {
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/service-role/export_prison_incidents-move",
        "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/service-role/export_prison_performance-move"
      ]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]

    resources = [
      "arn:aws:s3:::${module.ap_landing_bucket.bucket.id}/*"
    ]
  }
}

# don't attach poicy directly - use the module
# resource "aws_s3_bucket_policy" "allow_ap_write_to_landing" {
#   bucket = module.ap_landing_bucket.bucket.id
#   policy = data.aws_iam_policy_document.allow_ap_write_to_landing.json
# }

#------------------------------------------------------------------------------
# KMS setup for S3
#------------------------------------------------------------------------------

resource "aws_kms_key" "s3" {
  description         = "Encryption key for s3"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.s3-kms.json

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-s3-kms"
    }
  )
}

resource "aws_kms_alias" "kms-alias" {
  name          = "alias/s3"
  target_key_id = aws_kms_key.s3.arn
}

data "aws_iam_policy_document" "s3-kms" {
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_109
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}