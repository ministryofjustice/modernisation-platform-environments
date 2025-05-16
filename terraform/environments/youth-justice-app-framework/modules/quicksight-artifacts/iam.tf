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