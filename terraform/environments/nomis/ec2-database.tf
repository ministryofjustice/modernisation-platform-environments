#------------------------------------------------------------------------------
# Instance profile to be assumed by the ec2 database instances
# This is based on the ec2-common-profile but also gives access to an S3 bucket
# in which database backups are stored
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
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    aws_iam_policy.ec2_common_policy.arn
  ]

  tags = merge(
    local.tags,
    {
      Name = "ec2-database-role"
    },
  )
}

# attach database backup bucket access policy inline
# we managed the attachment separately as additional inline policies are attached
# to the role in the nomis_stack module
resource "aws_iam_role_policy" "s3_db_backup_bucket_access" {
  name   = "nomis-db-backup-bucket-access"
  role   = aws_iam_role.ec2_common_role.name
  policy = data.aws_iam_policy_document.s3_db_backup_bucket_access.json
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