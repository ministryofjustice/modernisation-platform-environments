resource "aws_iam_user" "s3_migration_user" {
  name = "s3-migration-user"
}

resource "aws_iam_role" "s3_migration_role" {
  name               = "S3MigrationRole"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/s3-migration-user"
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        }
    ]
}
EOF
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Policy to allow S3 access for S3 migration role"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:GetObjectTagging",
                "s3:GetObjectVersion",
                "s3:GetObjectVersionTagging"
            ],
            "Resource": [
                "arn:aws:s3:::moj-cur-reports-v2-hourly",
                "arn:aws:s3:::moj-cur-reports-v2-hourly?/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:PutObjectTagging",
                "s3:GetObjectTagging",
                "s3:GetObjectVersion",
                "s3:GetObjectVersionTagging"
            ],
            "Resource": [
                "arn:aws:s3:::cur-v2-hourly",
                "arn:aws:s3:::cur-v2-hourly/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.s3_migration_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}
