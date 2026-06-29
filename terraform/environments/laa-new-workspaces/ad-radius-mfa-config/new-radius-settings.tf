##############################################
### RADIUS Configuration for MFA
###
### Configures RADIUS settings on AWS Managed Microsoft AD
### for multi-factor authentication with WorkSpaces.
###
### Deployed AFTER:
###   1. workspace-components (RADIUS server must be running)
###   2. root module (AD directory must exist)
###   3. Manual LinOTP configuration (LDAP resolver, realm, policies)
###
### Remote state consumed:
###   - root module: directory_id
###   - workspace-components: radius_server_private_ips, radius_shared_secret_arn
##############################################

resource "aws_directory_service_radius_settings" "workspaces_ad_radius" {

  directory_id   = data.terraform_remote_state.root.outputs.directory_id
  radius_servers = data.terraform_remote_state.workspace_components.outputs.radius_server_private_ips

  radius_port             = 1812
  radius_timeout          = 5
  radius_retries          = 3
  shared_secret           = data.aws_secretsmanager_secret_version.radius_shared_secret.secret_string
  authentication_protocol = "PAP"
  display_label           = "MFA"
  use_same_username       = true
}

##############################################
### RADIUS Shared Secret
### (created in workspace-components, referenced here)
##############################################

data "aws_secretsmanager_secret" "radius_shared_secret" {
  arn = data.terraform_remote_state.workspace_components.outputs.radius_shared_secret_arn
}

data "aws_secretsmanager_secret_version" "radius_shared_secret" {
  secret_id = data.aws_secretsmanager_secret.radius_shared_secret.id
}
