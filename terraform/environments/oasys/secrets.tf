# Get secret by name for environment management
# Get secret by name for environment management
resource "random_password" "db_password" {
  length  = 30
  special = false
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_ssm_parameter" "db_password" {

  name        = "/database/oasys/rds_root_password"
  description = "RDS password"
  type        = "SecureString"
  value       = random_password.db_password.result

}