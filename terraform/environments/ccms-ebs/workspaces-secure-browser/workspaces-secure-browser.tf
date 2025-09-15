### SECURITY GROUP

module "workspacesweb_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions


  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name   = "workspacesweb"
  vpc_id = data.aws_vpc.shared.id

  /* DEBUGGING */
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  /* DEBUGGING */
}

### NETWORK SETTINGS

resource "awscc_workspacesweb_network_settings" "main" {


  vpc_id             = data.aws_vpc.shared.id
  subnet_ids         = [data.aws_subnet.private_aza.id, data.aws_subnet.private_azc.id]
  security_group_ids = [module.workspacesweb_security_group.security_group_id]
}


### WORKSPACES WEB PORTAL

resource "awscc_workspacesweb_portal" "main" {

  display_name         = "laa-workspaces-web"
  network_settings_arn = awscc_workspacesweb_network_settings.main.network_settings_arn
  user_settings_arn    = awscc_workspacesweb_user_settings.main.user_settings_arn
}

### USER SETTINGS

# Create a user settings configuration
resource "awscc_workspacesweb_user_settings" "main" {


  # Required settings
  copy_allowed     = "Enabled"
  download_allowed = "Enabled"
  paste_allowed    = "Enabled"
  print_allowed    = "Disabled"
  upload_allowed   = "Enabled"

  # Optional settings
  deep_link_allowed                  = "Enabled"
  disconnect_timeout_in_minutes      = 60
  idle_disconnect_timeout_in_minutes = 15

  toolbar_configuration = {
    hidden_toolbar_items = ["Microphone", "Webcam"] # These need doing manually, they didn't apply properly via Terraform
  }
}