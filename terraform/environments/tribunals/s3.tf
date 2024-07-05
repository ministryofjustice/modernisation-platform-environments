resource "aws_s3_bucket" "ebs_backup" {
  bucket = "tribunals-ebs-backup-${local.environment}"
}

resource "aws_s3_bucket_policy" "backup_bucket_policy" {
  bucket = aws_s3_bucket.ebs_backup.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          "AWS" : "${aws_iam_role.ec2_instance_role.arn}"
        },
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.ebs_backup.arn}",
          "${aws_s3_bucket.ebs_backup.arn}/*"
        ]
      }
    ]
  })
}
