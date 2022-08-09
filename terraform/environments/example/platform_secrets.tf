######################### Run Terraform via CICD ##################################
#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "db_password" {
  #checkov:skip=CKV_AWS_149
  name                    = "${var.networking[0].application}-database-password"
  recovery_window_in_days = 0
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

######################### Run Terraform via CICD ##################################


######################### Run Terraform Plan Locally Only ##################################
# To run a Terraform Plan locally, uncomment this bottom section of code and comment out the top section

# # Get secret by arn for environment management
# data "aws_ssm_parameter" "environment_management_arn" {
#   name = "environment_management_arn"
# }
#
# data "aws_secretsmanager_secret" "environment_management" {
#   arn = data.aws_ssm_parameter.environment_management_arn.value
# }
# # Get latest secret value with ID from above. This secret stores account IDs for the Modernisation Platform sub-accounts
# data "aws_secretsmanager_secret_version" "environment_management" {
#   secret_id = data.aws_secretsmanager_secret.environment_management.id
# }

######################### Run Terraform Plan Locally Only ##################################
