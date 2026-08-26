
variable "user_name" {
  type    = string
  default = "datafactory-user"
}

resource "aws_iam_user" "datafactory_user" {
  name = "${var.user_name}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_iam_user_policy" "assume_external_role" {
  name = "assume-datafactory-dev-role"
  user = aws_iam_user.datafactory_user.name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sts:AssumeRole"
        ]

        Resource = "arn:aws:iam::${data.aws_secretsmanager_secret_version.external_account_id.secret_string}:role/datafactory_dev_assume_role"
      }
    ]
  })
}


# resource "aws_iam_user_login_profile" "datafactory_user" {
#   user                    = aws_iam_user.datafactory_user.name
#   password_reset_required = false
# }

# Create programmatic access credentials
resource "aws_iam_access_key" "datafactory_user" {
  user = aws_iam_user.datafactory_user.name
}

# Create secret to store credentials
resource "aws_secretsmanager_secret" "datafactory_user_credentials" {
  name = "datafactory/${var.user_name}/credentials"
}


resource "aws_secretsmanager_secret_version" "datafactory_user_credentials" {
  #checkov:skip=CKV2_AWS_57: "Secret only exists for testing — rotation not applicable"
  secret_id = aws_secretsmanager_secret.datafactory_user_credentials.id

  secret_string = jsonencode({
    username          = aws_iam_user.datafactory_user.name
    # password          = aws_iam_user_login_profile.datafactory_user.password
    access_key_id     = aws_iam_access_key.datafactory_user.id
    secret_access_key = aws_iam_access_key.datafactory_user.secret
  })
}