# Create s3 bucket for s3 keys
module "s3_bucket_ssh_keys" {
  #checkov:skip=CKV_TF_1

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"

  bucket_name = "${var.account_info.application_name}-${var.env_name}-oracle-${var.db_suffix}-ssh-keys"

  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  custom_kms_key      = var.account_config.kms_keys.general_shared

  providers = {
    aws.bucket-replication = aws.bucket-replication
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

  tags = var.tags
}


# Create an s3 object for each public key
resource "aws_s3_object" "user_public_keys" {
  for_each = var.public_keys

  bucket     = module.s3_bucket_ssh_keys.bucket.id
  key        = "public-keys/${each.key}.pub"
  content    = each.value
  kms_key_id = var.account_config.kms_keys.general_shared

  tags = merge(
    var.tags,
    {
      Name = "${var.account_info.application_name}-${var.env_name}-${each.key}-${var.db_suffix}-publickey"
    }
  )

}

data "aws_iam_policy_document" "db_ssh_keys_s3_policy_document" {

  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject"
    ]
    resources = ["${module.s3_bucket_ssh_keys.bucket.arn}/logs/*"]
  }

  statement {
    actions = [
      "s3:GetObject"
    ]
    resources = ["${module.s3_bucket_ssh_keys.bucket.arn}/public-keys/*"]
  }

  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [module.s3_bucket_ssh_keys.bucket.arn]

    condition {
      test = "ForAnyValue:StringEquals"
      values = [
        "public-keys/",
        "logs/"
      ]
      variable = "s3:prefix"
    }
  }

  statement {
    actions = [

      "kms:Encrypt",
      "kms:Decrypt",
    ]
    resources = [var.account_config.kms_keys.general_shared]
  }
}

resource "aws_iam_policy" "db_ssh_keys_s3" {
  name   = "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-ssh-keys-s3"
  policy = data.aws_iam_policy_document.db_ssh_keys_s3_policy_document.json
}

#resource "aws_iam_role_policy_attachment" "db_ssh_keys_s3" {
#  policy_arn = aws_iam_policy.db_ssh_keys_s3.arn
#  role       = aws_iam_role.db_ec2_instance_iam_role.name
#}
