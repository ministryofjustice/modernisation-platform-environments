# Create s3 bucket for s3 keys
module "s3_bucket_ssh_keys" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"

  bucket_name = "${var.env_name}-oracle-database-ssh-keys"

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
      Name = "bastion-${var.env_name}-${each.key}-publickey"
    }
  )

}

