# Get secret by name for environment management
#tfsec:ignore:AWS095
data "aws_secretsmanager_secret" "environment_management" {
  #checkov:skip=CKV_AWS_149
  provider = aws.modernisation-platform
  name     = "environment_management"
}

# Get latest secret value with ID from above. This secret stores account IDs for the Modernisation Platform sub-accounts
data "aws_secretsmanager_secret_version" "environment_management" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.environment_management.id
}

## == DATABASE CONNECTIONS ==

# Get secret by name for database password
# data "aws_secretsmanager_secret" "database_password" {
#   name = "performance_hub_db"
# }

# data "aws_secretsmanager_secret_version" "database_password" {
#   secret_id = data.aws_secretsmanager_secret.database_password.arn
# }

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "db_password" {
  #checkov:skip=CKV_AWS_149

  name = "${var.networking[0].application}-database-password"

  tags = merge(
    local.tags,
    {
      Name = "${var.networking[0].application}-db-password"
    },
  )
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.random_password.result
}
