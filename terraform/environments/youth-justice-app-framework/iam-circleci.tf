resource "aws_iam_openid_connect_provider" "circleci" {
  url = "https://oidc.circleci.com/org/3c8b8a35-eba8-48df-a553-b0f1435cb75d"

  client_id_list = [
    "3c8b8a35-eba8-48df-a553-b0f1435cb75d"
  ]

  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b365bbc8ba2d543ce" # CircleCI's known thumbprint
  ]
}

resource "aws_iam_role" "circleci_role" {
  name = "circleci-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.circleci.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "oidc.circleci.com/org/3c8b8a35-eba8-48df-a553-b0f1435cb75d:aud" = "3c8b8a35-eba8-48df-a553-b0f1435cb75d"
          }
        }
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "circleci_policy" {
  role       = aws_iam_role.circleci_role.name
  policy_arn = "arn:aws:iam::aws:policy/<your-policy>"
}
