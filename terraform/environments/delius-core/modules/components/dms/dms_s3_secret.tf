# Since the DMS S3 bucket is generated with an arbitrary suffix, we need to store the name
# in a well known location so that other accounts may find it.   Therefore we create an
# Secrets Manager Secret to store the bucket name.  
locals {
  dms_s3_local_bucket_name = jsonencode({bucket_name = module.s3_bucket_dms_destination.bucket.bucket})
}


resource "aws_secretsmanager_secret" "dms_s3_local_bucket_secret" {
  name          = local.dms_s3_local_bucket_secret
  description   = "Name of s3 Bucket for DMS Replication"
  kms_key_id    = var.account_config.kms_keys.general_shared
  tags          = var.tags
}

resource "aws_secretsmanager_secret_version" "dms_s3_local_bucket_secret_version" {
  secret_id     = aws_secretsmanager_secret.dms_s3_local_bucket_secret.id
  secret_string = local.dms_s3_local_bucket_name
}

# Create a role which will have access to this secret
resource "aws_iam_role" "dms_s3_local_bucket_secret_access_role" {
  name = local.dms_s3_local_bucket_secret_access_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_info.id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "dms_s3_local_bucket_secret_access_role_policy" {
  name = "AllowSecretsManagerAccess"
  role = aws_iam_role.dms_s3_local_bucket_secret_access_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.dms_s3_local_bucket_secret.arn
      }
    ]
  })
}


# Define which accounts have access to this secret.   Those are:
#  1. List of all Audit Clients of the current account [0, 1 or more accounts]
#     (This will be an empty list if no audit replication is required, or if this account is itself an audit client)
#  2. The Audit Repository for the current account [0 or 1 accounts]
#     (This will be an empty list if no audit replication is required, or if this account is itself an audit repository)
# No account may be simultaneouesly both an Audit Client and Audit Repository.  It may be Client or Repository, or neither.
locals {
  dms_s3_local_bucket_secret_access_role_arns = nonsensitive([for account_id in compact(concat(var.dms_config.client_account_ids,[local.dms_repository_account_id])) : "arn:aws:iam::${account_id}:role/${local.dms_s3_local_bucket_secret_access_role}"])
}

data "aws_iam_role" "dms_s3_local_bucket_secret_access_roles" {
   for_each = toset(local.dms_s3_local_bucket_secret_access_role_arns)
   name     = split("/",each.key)[length(split("/",each.key)) - 1]
}

# Filter the roles which have access to this secret to those which already exist
# This avoids a terraform error regarding an unsupported principal
locals {
  dms_s3_local_bucket_secret_access_role_arns_existing = [
    for role in data.aws_iam_role.dms_s3_local_bucket_secret_access_roles :
      role.arn if try(role.id != null, false)
  ]
}

data "aws_iam_policy_document" "dms_s3_local_bucket_secret" {
  statement {
    sid    = "AllowAuditRepositoryAndClientsToReadTheBucketName"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = local.dms_s3_local_bucket_secret_access_role_arns_existing
    }
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.dms_s3_local_bucket_secret.arn]
  }
}


resource "aws_secretsmanager_secret_policy" "dms_s3_local_bucket_secret_policy" {
  secret_arn = aws_secretsmanager_secret.dms_s3_local_bucket_secret.arn
  policy     = data.aws_iam_policy_document.dms_s3_local_bucket_secret.json
}

