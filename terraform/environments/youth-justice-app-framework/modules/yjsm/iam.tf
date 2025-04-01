resource "aws_iam_role" "yjsm_ec2_role" {
  name = "yjsm-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_secretsmanager_secrets" "all_secrets" {}

resource "aws_iam_instance_profile" "yjsm_ec2_profile" {
  name = "yjsm-ec2-instance"
  role = aws_iam_role.yjsm_ec2_role.name
}

#todo add missing policies to this role
resource "aws_iam_role_policy_attachment" "yjsm_ssm_policy" {
  role       = aws_iam_role.yjsm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "yjsm_cloudwatch_policy" {
  role       = aws_iam_role.yjsm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "yjsm_ec2_readonly_policy" {
  role       = aws_iam_role.yjsm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "yjsm_s3_readonly_policy" {
  role       = aws_iam_role.yjsm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}


resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "secrets_manager_access"
  description = "Policy to allow access to specific secrets in Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets"
        ]
        Effect   = "Allow"
        Resource = data.aws_secretsmanager_secrets.all_secrets.arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secrets_manager_policy" {
  role       = aws_iam_role.yjsm_ec2_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}