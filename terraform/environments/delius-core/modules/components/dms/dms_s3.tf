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
            [for k,v in local.repository_account_map : "arn:aws.iam::${v}:role/${k}-dms-s3-writer-role"],
            [for k,v in local.client_account_map : "arn:aws.iam::${v}:role/${k}-dms-s3-writer-role"],
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