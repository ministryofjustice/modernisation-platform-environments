resource "aws_iam_role" "cis_ec2_role" {
  name = "${local.application_name_short}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  inline_policy {
    name = "${local.application_name_short}-ec2-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = "s3:*"
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
} 