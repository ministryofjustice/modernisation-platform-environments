
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



  #### Secret for SNS email address ###
resource "aws_secretsmanager_secret" "support_email_account" {
  name        = "Application_email_account"
  description = "email address of the support account for cw alerts"
  recovery_window_in_days = 0
}


resource "aws_secretsmanager_secret_version" "support_email_account" {
  secret_id     = aws_secretsmanager_secret.support_email_account.id
  secret_string = "umesh.ray@lumen.com"
  lifecycle {
    ignore_changes = [secret_string, ]
  }
}
