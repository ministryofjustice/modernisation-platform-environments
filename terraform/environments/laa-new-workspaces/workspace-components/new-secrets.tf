##############################################
### Shared Secrets for RADIUS and LinOTP
###
### References to existing secrets used by ECS
##############################################

##############################################
### RADIUS Shared Secret (existing)
##############################################

data "aws_secretsmanager_secret" "radius_shared_secret" {
  name = "laa-new-workspaces-development-radius-secret-20260624145923126200000005"
}

# Alias for backward compatibility with resource references
resource "null_resource" "radius_shared_secret" {
  triggers = {
    arn = data.aws_secretsmanager_secret.radius_shared_secret.arn
  }
}

# Create a local value to reference as if it were a resource
locals {
  radius_shared_secret_arn = data.aws_secretsmanager_secret.radius_shared_secret.arn
}

##############################################
### LinOTP Admin Password (existing)
##############################################

data "aws_secretsmanager_secret" "linotp_admin_password" {
  name = "laa-new-workspaces-development-linotp-admin-20260507100708118500000001"
}

# Alias for backward compatibility
resource "null_resource" "linotp_admin_password" {
  triggers = {
    arn = data.aws_secretsmanager_secret.linotp_admin_password.arn
  }
}

locals {
  linotp_admin_password_arn = data.aws_secretsmanager_secret.linotp_admin_password.arn
}

