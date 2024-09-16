# We use an S3 bucket for staging DMS Replication data between different environments.
# Within Modernisation Platform it is not possible for a DMS instance to have endpoints within
# different accounts.  However it IS possible for S3 buckets to be readable/writeable from 
# other accounts.
# Therefore as a workaround we use S3 to stage DMS replication data between accounts.
# A DMS Instance in a source account will have a source endpoint in the local account's database and 
# a target endpoint on an S3 bucket in the target account.
# A DMS Instance in a target account will have a target endpoint in the local account's S3
# bucket and a target endpoint in the local account's database.
# We share the S3 bucket to allow this data to be replicated between accounts.
# Therefore each account must have a single S3 bucket used for staging during DMS replication.
module "s3_bucket_dms_destination" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.1.0"

  bucket_prefix      = "${local.dms_s3_local_bucket_prefix}"
  versioning_enabled = false

  providers = {
    aws.bucket-replication = aws
  }

  # We set the bucket policy to allow writing from any of the following:
  #   (1) The writer role in the repository used by this environment, if this environment is a client.
  #   (2) The writer role in all clients feeding to this environment, if this environment is a repository.
  #   (3) The writer role in this environment.
  bucket_policy_v2 = [{
          effect     = "Allow"
          principals = {
            type        = "AWS"
            identifiers = flatten(concat(
            [for k,v in local.repository_account_map : "arn:aws:iam::${v}:role/${k}-dms-s3-writer-role"],
            [for k,v in local.client_account_map : "arn:aws:iam::${v}:role/${k}-dms-s3-writer-role"],
            [aws_iam_role.dms_s3_writer_role.arn]))
          }
          actions    = [
            "s3:PutObject",
            "s3:PutObjectAcl",
            "s3:DeleteObject",
            "s3:PutObjectTagging",
            "s3:ListBucket"
          ]
        },{
          effect     = "Allow"
          principals = {
            type        = "AWS"
            identifiers = [aws_iam_role.dms_s3_reader_role.arn]
          }
          actions    = [
            "s3:GetObject",
            "s3:ListBucket"
          ]
        }]

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

# Store the name of the S3 bucket in AWS Secrets Manager
resource "aws_secretsmanager_secret" "s3_bucket_name" {
  name = "${var.env_name}-dms-s3-bucket-name"
  description = "The name of the S3 bucket used for DMS replication"
}

resource "aws_secretsmanager_secret_version" "s3_bucket_name" {
  secret_id = aws_secretsmanager_secret.s3_bucket_name.id
  secret_string = module.s3_bucket_dms_destination.bucket.bucket
}


# Create a bucket policy to allow all required accounts to read the secret

data "aws_iam_policy_document" "s3_bucket_name_secret" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.s3_bucket_name.arn
    ]

    principals {
      type        = "AWS"
      identifiers = [for k,v in local.bucket_list_target_map : "arn:aws:iam::${v}:role/github-actions"]
    }
  }
}

resource "aws_secretsmanager_secret_policy" "s3_bucket_name" {
  secret_arn = aws_secretsmanager_secret.s3_bucket_name.id
  policy = data.aws_iam_policy_document.s3_bucket_name_secret.json
}
