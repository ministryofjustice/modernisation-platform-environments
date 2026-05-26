##############################################
### RADIUS Configuration for MFA
###
### Configures RADIUS settings on AWS Managed Microsoft AD
### for multi-factor authentication with WorkSpaces.
###
### RADIUS shared secret and servers are created in
### workspace-components and consumed via remote state.
##############################################

##############################################
### RADIUS Configuration for Directory
##############################################

resource "aws_directory_service_radius_settings" "workspaces_ad_radius" {
  count = local.environment == "development" ? 1 : 0

  directory_id = aws_directory_service_directory.workspaces_ad[0].id

  # RADIUS server endpoints from workspace-components remote state
  # These will be empty until EC2 instances are deployed in workspace-components
  radius_servers = data.terraform_remote_state.workspace_components.outputs.radius_server_private_ips

  radius_port             = 1812
  radius_timeout          = 5
  radius_retries          = 3
  shared_secret           = data.aws_secretsmanager_secret_version.radius_shared_secret[0].secret_string
  authentication_protocol = "PAP"
  display_label           = "MFA"
  use_same_username       = true

  depends_on = [
    aws_directory_service_directory.workspaces_ad
  ]

  # Prevent Terraform from updating RADIUS settings after initial creation
  # AWS validation often fails even when RADIUS is working correctly
  lifecycle {
    ignore_changes = all
  }
}

##############################################
### Get RADIUS Shared Secret from Secrets Manager
### (Created in workspace-components)
##############################################

data "aws_secretsmanager_secret" "radius_shared_secret" {
  count = local.environment == "development" ? 1 : 0

  arn = data.terraform_remote_state.workspace_components.outputs.radius_shared_secret_arn
}

data "aws_secretsmanager_secret_version" "radius_shared_secret" {
  count = local.environment == "development" ? 1 : 0

  secret_id = data.aws_secretsmanager_secret.radius_shared_secret[0].id
}

##############################################
### Outputs for RADIUS Configuration
##############################################

output "radius_configuration_complete" {
  description = "Indicates if RADIUS configuration is complete"
  value       = try(aws_directory_service_radius_settings.workspaces_ad_radius[0].id != null, false)
}
