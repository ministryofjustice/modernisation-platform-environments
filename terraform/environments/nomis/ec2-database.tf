#------------------------------------------------------------------------------
# Instance profile to be assumed by the ec2 database instances
# This is required to enable SSH via Systems Manager
# and also to allow access to an S3 bucket in which
# Oracle and Weblogic installation files are held
#------------------------------------------------------------------------------
resource "aws_iam_role" "ec2_database_role" {
  name                 = "ec2-database-role"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
  inline_policy {
    name   = "custom-SSM-manged-instance-core-for-db"
    policy = data.aws_iam_policy_document.ssm_custom.json
  }
  inline_policy {
    name   = "nomis-apps-bucket-access-for-db"
    policy = data.aws_iam_policy_document.s3_bucket_access.json
  }

  inline_policy {
    name   = "nomis-apps-bucket-access-for-db-backup"
    policy = data.aws_iam_policy_document.s3_db_backup_bucket_access.json
  }

  inline_policy {
    name   = "session-manager-logging-db"
    policy = data.aws_iam_policy_document.session_manager_logging.json
  }

  tags = merge(
    local.tags,
    {
      Name = "ec2-database-role"
    },
  )
}



# create instance profile from IAM role
resource "aws_iam_instance_profile" "ec2_database_profile" {
  name = "ec2-database-profile"
  role = aws_iam_role.ec2_database_role.name
  path = "/"
}

data "aws_iam_policy_document" "s3_db_backup_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [module.nomis-db-backup-bucket.bucket.arn,
    "${module.nomis-db-backup-bucket.bucket.arn}/*"]
  }
}
