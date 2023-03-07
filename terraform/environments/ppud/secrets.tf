
# Firstly create a random generated password to use in secrets.

resource "random_password" "password" {
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = true
}

# Creating a AWS secret versions for AWS managed AD

resource "aws_secretsmanager_secret" "secretdirectoryservice" {
  name                    = "AWSADPASS"
  recovery_window_in_days = 0
}

# Creating a AWS secret versions for AWS managed AD

resource "aws_secretsmanager_secret_version" "sversion" {
  secret_id     = aws_secretsmanager_secret.secretdirectoryservice.id
  secret_string = random_password.password.result
}
