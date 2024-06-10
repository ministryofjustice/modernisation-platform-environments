# resource "aws_s3_bucket" "chaps-db-backup-bucket" {
#   bucket = local.application_data.accounts[local.environment].s3_bucket_name
# }

# resource "aws_iam_role" "S3_db_backup_restore_access" {
#   name               = "s3-db-backup-access-role"
#   assume_role_policy = data.aws_iam_policy_document.s3-access-policy.json
# }

# data "aws_iam_policy_document" "s3-access-policy" {
#   version = "2012-10-17"
#   statement {
#     effect = "Allow"
#     actions = [
#       "sts:AssumeRole"
#     ]
#     principals {
#       type = "Service"
#       identifiers = [
#         "rds.amazonaws.com",
#         "ec2.amazonaws.com",
#       ]
#     }
#   }
# }

# resource "aws_iam_policy" "s3_db_backup_restore_policy" {
#   name        = "s3-db-restore-policy"
#   description = "Policy to allow RDS access to S3 bucket for db restore"
#   policy = jsonencode({
#     Version : "2012-10-17",
#     Statement : [
#       {
#         Effect : "Allow",
#         Action : [
#           "kms:DescribeKey",
#           "kms:GenerateDataKey",
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "s3:GetObject",
#           "s3:ListBucket",
#           "s3:PutObject"
#         ],
#         Resource = [
#           "arn:aws:s3:::local.application_data.accounts[local.environment].s3_bucket_name",
#           "arn:aws:s3:::local.application_data.accounts[local.environment].s3_bucket_name/"
#         ]
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "s3_db_restore_policy_attach" {
#   role       = aws_iam_role.S3_db_backup_restore_access.name
#   policy_arn = aws_iam_policy.s3_db_backup_restore_policy.arn
# }
