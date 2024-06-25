resource "aws_kms_key" "athena_workspace_result_encryption_key" {
  description         = "KMS key for encrypting the default Athena Workspace's results"
  enable_key_rotation = true

  policy = jsonencode(
    {
      "Id": "key-default",
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "Enable IAM User Permissions",
          "Effect": "Allow",
          "Principal": {
            "AWS": "arn:aws:iam::${local.env_account_id}:root"
          },
          "Action": "kms:*",
          "Resource": "*"
        },
        {
          "Sid": "Allow Athena use of the key",
          "Effect": "Allow",
          "Principal": {
            "Service": "athena.amazonaws.com"
          },
          "Action": [
            "kms:Encrypt*",
            "kms:Decrypt*",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:Describe*"
          ],
          "Resource": "*"
        },
        {
          "Sid" : "Enable log service Permissions",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "logs.eu-west-2.amazonaws.com"
          },
          "Action" : [
            "kms:Encrypt*",
            "kms:Decrypt*",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:Describe*"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
  tags = merge(
    local.tags,
    {
      Resource_Type = "KMS key for query result encryption used with default Athena Workgroup",
    }
  )
}

resource "aws_athena_workgroup" "default" {
  name = "default"
  description = "A default Athena workgroup to set query limits and link to the default query location bucket: ${module.athena-s3-bucket.bucket.id}"

  configuration {
    bytes_scanned_cutoff_per_query = 1073741824 # 1 GB
    enforce_workgroup_configuration    = false
    publish_cloudwatch_metrics_enabled = true
    
    result_configuration {
      output_location = "s3://${module.athena-s3-bucket.bucket.id}/output/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = aws_kms_key.athena_workspace_result_encryption_key.arn
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }

  }
  tags = merge(
    local.tags,
    {
      Resource_Type = "Athena Workgroup for default Query Result Location results, logs and query limits",
    }
  )
}
