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