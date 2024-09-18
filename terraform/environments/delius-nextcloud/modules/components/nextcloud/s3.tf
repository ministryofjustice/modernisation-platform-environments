module "s3_bucket_config" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v8.2.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix      = "${var.env_name}-config"
  versioning_enabled = true
  sse_algorithm      = "AES256"
  # Useful guide - https://aws.amazon.com/blogs/storage/how-to-use-aws-datasync-to-migrate-data-between-amazon-s3-buckets/
  bucket_policy_v2 = [{
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    principals = {
      type = "AWS"
      identifiers = [
        module.nextcloud_service.task_role_arn,
      ]
    }
  }]

  ownership_controls = "BucketOwnerEnforced" # Disable all S3 bucket ACL

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


resource "random_password" "nextcloud_password_salt" {
  length = 16
}

resource "aws_ssm_parameter" "nextcloud_secret" {
  name  = "/${var.env_name}/nextcloud/secret"
  type  = "SecureString"
  value = "replace_me"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

data "aws_ssm_parameter" "nextcloud_secret" {
  name = aws_ssm_parameter.nextcloud_secret.name
}

resource "aws_s3_object" "config" {
  bucket = module.s3_bucket_config.bucket.id
  key    = "config.json"
  content = templatefile("${path.module}/templates/nextcloud-conf.json.tftpl",
    {
      nextcloud_passwordsalt = random_password.nextcloud_password_salt.result,
      nextcloud_secret       = data.aws_ssm_parameter.nextcloud_secret.value,
      redis = {
        host = module.nextcloud_service.elasticache_endpoint
        port = module.nextcloud_service.elasticache_port
      },
      mail = {
        server       = "replace"
        from_address = "replace"
        domain       = "replace"
      }

      fileshare_user_base   = "ou=Fileshare,ou=Users,dc=moj,dc=com;ou=Users,dc=moj,dc=com"
      standard_user_base    = "ou=Users,dc=moj,dc=com"
      fs_group_prefix       = "RES-FS"
      ldap_host             = "ldap.dev.delius-core.hmpps-development.modernisation-platform.internal"
      pwm_url               = "pwm.dev.delius-core.hmpps-development.modernisation-platform.service.justice.gov.uk"
      fileshare_base_groups = "ou=Fileshare,ou=Groups,dc=moj,dc=com"
      ldap_admin_user       = "cn=admin,dc=moj,dc=com"

    }
  )
}
