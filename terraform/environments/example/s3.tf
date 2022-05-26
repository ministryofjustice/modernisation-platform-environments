#------------------------------------------------------------------------------
# S3 Bucket
#------------------------------------------------------------------------------
resource "aws_kms_key" "bastion_s3" {
  enable_key_rotation = true

  tags = merge(
    var.tags_common,
    {
      Name = "bastion_s3"
    },
  )
}

resource "aws_kms_alias" "bastion_s3_alias" {
  name          = "alias/s3-${var.bucket_name}_key"
  target_key_id = aws_kms_key.bastion_s3.arn
}

resource "random_string" "random6" {
  length  = 6
  special = false
}

module "s3-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.0.5"

  providers = {
    # Since replication_enabled is false, the below provider is not being used.
    # Therefore, just to get around the requirement, we pass the aws.share-tenant.
    # If replication was enabled, a different provider would be needed.
    aws.bucket-replication = aws
  }
  bucket_name         = "${var.bucket_name}-${var.tags_prefix}-${lower(random_string.random6.result)}"
  replication_enabled = false

#  lifecycle_rule = [
#     {
#       id      = "main"
#       enabled = "Enabled"
#       prefix  = ""

#       tags = {
#         rule      = "log"
#         autoclean = "true"
#       }

#       transition = [
#         {
#           days          = 90
#           storage_class = "STANDARD_IA"
#           }, 
#         {
#           days          = 365
#           storage_class = "GLACIER"
#         }
#       ]

#       expiration = {
#         days = 730
#       }

#       noncurrent_version_transition = [
#         {
#           days          = 90
#           storage_class = "STANDARD_IA"
#           }, {
#           days          = 365
#           storage_class = "GLACIER"
#         }
#       ]

#       noncurrent_version_expiration = {
#         days = 730
#       }
#     }
#   ]

  tags = merge(
    local.tags,
    {
      Name = "S3-${var.bucket_name}-${var.tags_prefix}-${lower(random_string.random6.result)}"
    },
  )
}

# resource "aws_s3_bucket_object" "bucket_public_keys_readme" {
#   bucket = module.s3-bucket.bucket.id

#   key        = "public-keys/README.txt"
#   content    = "Drop here the ssh public keys of the instances you want to control"
#   kms_key_id = aws_kms_key.bastion_s3.arn

#   tags = merge(
#     var.tags_common,
#     {
#       Name = "bastion-${var.app_name}-README.txt"
#     }
#   )

# }

resource "aws_s3_bucket_object" "user_public_keys" {
  for_each = var.public_key_data

  bucket     = module.s3-bucket.bucket.id
  key        = "public-keys/${each.key}.pub"
  content    = each.value
  kms_key_id = aws_kms_key.bastion_s3.arn

  tags = merge(
    var.tags_common,
    {
      Name = "bastion-${var.app_name}-${each.key}-publickey"
    }
  )

}
# #tfsec:ignore:AWS002 tfsec:ignore:AWS098
# resource "aws_s3_bucket" "example_bucket" {
#   #checkov:skip=CKV_AWS_18
#   #checkov:skip=CKV_AWS_144
#   #checkov:skip=CKV2_AWS_6
#   bucket = "${local.application_name}-example-${local.environment}"

#   lifecycle {
#     prevent_destroy = true
#   }

#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-example-s3"
#     }
#   )
# }

# resource "aws_s3_bucket_public_access_block" "example_bucket" {
#   bucket = aws_s3_bucket.example_bucket.id

#   block_public_acls   = true
#   block_public_policy = true
# }

# resource "aws_s3_bucket_acl" "example_bucket" {
#   bucket = aws_s3_bucket.example_bucket.id
#   acl    = "private"
# }

# resource "aws_s3_bucket_lifecycle_configuration" "example_bucket" {
#   bucket = aws_s3_bucket.example_bucket.id
#   rule {
#     id     = "tf-s3-lifecycle"
#     status = "Enabled"
#     noncurrent_version_transition {
#       noncurrent_days = 30
#       storage_class   = "STANDARD_IA"
#     }
#       transition {
#       days          = 60
#       storage_class = "STANDARD_IA"
#     }
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "example_bucket" {
#   bucket = aws_s3_bucket.example_bucket.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm     = "aws:kms"
#       kms_master_key_id = aws_kms_key.s3.arn
#     }
#   }
# }

# resource "aws_s3_bucket_versioning" "example_bucket" {
#   bucket = aws_s3_bucket.example_bucket.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# #S3 bucket access policy
# resource "aws_iam_policy" "s3_example_bucket_policy" {
#   name   = "${local.application_name}-s3-example-bucket-policy"
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:DescribeKey",
#         "kms:GenerateDataKey",
#         "kms:Encrypt",
#         "kms:Decrypt"
#       ],
#       "Resource": "${aws_kms_key.s3.arn}"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "s3:ListBucket",
#         "s3:GetBucketLocation"
#       ],
#       "Resource": [
#           "${aws_s3_bucket.example_bucket.arn}"
#       ]
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "s3:GetObjectMetaData",
#         "s3:GetObject",
#         "s3:PutObject",
#         "s3:ListMultipartUploadParts",
#         "s3:AbortMultipartUpload"
#       ],
#       "Resource": [
#         "${aws_s3_bucket.example_bucket.arn}/*"
#       ]
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role" "s3_example_bucket_role" {
#   name               = "${local.application_name}-s3-example-bucket-role"
#   assume_role_policy = data.aws_iam_policy_document.s3-access-policy.json
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-s3-example-bucket-role"
#     }
#   )
# }

# resource "aws_iam_role_policy_attachment" "s3_dexample_bucket_attachment" {
#   role       = aws_iam_role.s3_example_bucket_role.name
#   policy_arn = aws_iam_policy.s3_example_bucket_policy.arn
# }
# #------------------------------------------------------------------------------
# # KMS setup for S3
# #------------------------------------------------------------------------------

# resource "aws_kms_key" "s3" {
#   description         = "Encryption key for s3"
#   enable_key_rotation = true
#   policy              = data.aws_iam_policy_document.s3-kms.json

#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-s3-kms"
#     }
#   )
# }

# resource "aws_kms_alias" "kms-alias" {
#   name          = "alias/s3"
#   target_key_id = aws_kms_key.s3.arn
# }

# data "aws_iam_policy_document" "s3-kms" {
#   #checkov:skip=CKV_AWS_111
#   #checkov:skip=CKV_AWS_109
#   statement {
#     effect    = "Allow"
#     actions   = ["kms:*"]
#     resources = ["*"]

#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cicd-member-user"]
#     }
#   }
# }