# 2. IAM Role and Policy for Glue - TODO populate this with the iam you need
## Probably need aws_iam_role, aws_iam_policy, aws_iam_role_policy_attachment

### Guessing IAM:

#resource "aws_iam_role" "glue_role" {
#  name = var.glue_role_name
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [
#      {
#        Effect = "Allow",
#        Principal = {
#          Service = "glue.amazonaws.com"
#        },
#        Action = "sts:AssumeRole"
#      }
#    ]
#  })
#}
#
#resource "aws_iam_policy" "glue_policy" {
#  name        = "${var.glue_role_name}-policy"
#  description = "Policy for Glue job to access RDS and S3"
#
#  policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [
#      {
#        Effect = "Allow",
#        Action = [
#          "s3:*",
#          "rds:*",
#          "glue:*",
#          "logs:*",
#          "cloudwatch:*",
#          "ec2:CreateNetworkInterface",
#          "ec2:DeleteNetworkInterface",
#          "ec2:DescribeNetworkInterfaces",
#          "ec2:AttachNetworkInterface",
#          "ec2:DetachNetworkInterface"
#        ],
#        Resource = "*"
#      }
#    ]
#  })
#}
#
#resource "aws_iam_role_policy_attachment" "glue_policy_attachment" {
#  role       = aws_iam_role.glue_role.name
#  policy_arn = aws_iam_policy.glue_policy.arn
#}