#Iam bits for lambda rotation
resource "aws_iam_role" "rds_export_to_s3_role" {
  name = "rds-export-to-s3-role-yjb-case-reporting"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "rds_export_to_s3_policy" {
  name        = "rds-export-to-s3-role-yjb-case-reporting"
  description = "Allows RDS to export to S3 for yjb case reporting"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:AbortMultipartUpload"
        ],
        "Resource" : "arn:aws:s3:::moj-${local.environment}-redshift-yjb-reporting/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_export_to_s3_policy_attachment" {
  role       = aws_iam_role.rds_export_to_s3_role.name
  policy_arn = aws_iam_policy.rds_export_to_s3_policy.arn
}
