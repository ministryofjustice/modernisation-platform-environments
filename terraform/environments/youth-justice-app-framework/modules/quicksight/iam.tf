# Create a role to allow quicksight to create a VPC connection
resource "aws_iam_role" "vpc_connection_role" {
  name        = "create-quicksight-vpc-connection"
  description = "Rule to allow the Quicksite service to create a VPC connection."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "qs_vpc" {
  #checkov:skip=CKV_AWS_355: [TODO] Consider making the Resource reference more restrictive.
  #checkov:skip=CKV_AWS_290: [TODO] Consider adding Constraints.
  name = "QuickSightVPCConnectionRolePolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "qs_vpc" {
  role       = aws_iam_role.vpc_connection_role.name
  policy_arn = aws_iam_policy.qs_vpc.arn
}

resource "aws_iam_policy" "qs_kms" {
  name = "QuickSightKMSReadPolicy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : "kms:Decrypt",
        "Resource" : "arn:aws:kms:eu-west-2:${var.account_id}:key/*"
      }
    ]
  })
}

data "aws_iam_role" "secrets" {
  name = "aws-quicksight-secretsmanager-role-v0"
}

resource "aws_iam_role_policy_attachment" "kms" {

  role       = data.aws_iam_role.secrets.name
  policy_arn = aws_iam_policy.qs_kms.arn
}