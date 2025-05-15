

resource "aws_iam_policy" "qs_vpc" {
  name        = "QuickSightVPCConnectionRolePolicy"
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
  name        = "QuickSightKMSReadPolicy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "kms:Decrypt",
            "Resource": "arn:aws:kms:eu-west-2:711387140977:key/*"
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