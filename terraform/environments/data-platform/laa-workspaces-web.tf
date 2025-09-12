### DATA

data "aws_subnet" "private_aza" {
  filter {
    name   = "tag:Name"
    values = ["${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-eu-west-2a"]
  }
}

data "aws_subnet" "private_azc" {
  filter {
    name   = "tag:Name"
    values = ["${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-eu-west-2c"]
  }
}

### SECURITY GROUP

module "workspacesweb_security_group" {

  count = local.environment == "test" ? 1 : 0

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name   = "workspacesweb"
  vpc_id = data.aws_vpc.shared.id

  ingress_cidr_blocks = ["10.10.0.0/16"]
  ingress_rules       = ["https-443-tcp"]
  egress_cidr_blocks  = ["172.20.0.0/16"]
  egress_rules        = ["https-443-tcp"]
}

### NETWORK SETTINGS

resource "awscc_workspacesweb_network_settings" "main" {

  count = local.environment == "test" ? 1 : 0

  vpc_id             = data.aws_vpc.shared.id
  subnet_ids         = [data.aws_subnet.private_aza.id, data.aws_subnet.private_azc.id]
  security_group_ids = [module.workspacesweb_security_group[0].security_group_id]
}

### IDENTITY PROVIDER

/*

This is currently commented out as the identity provider needs to be created to produce the ServiceProviderMetadata, which is upload to Entra ID
which then produces the IDPMetadata which is required to create the identity provider
 --- chicken and egg situation ---

resource "awscc_workspacesweb_identity_provider" "main" {

  count = local.environment == "test" ? 1 : 0

  identity_provider_name = "laa-idp"
  identity_provider_type = "SAML"
  identity_provider_details = {
    MetadataFile = "${path.module}/src/idp-metadata.xml"
  }
  portal_arn = awscc_workspacesweb_portal.main[0].portal_arn
}

*/


### WORKSPACES WEB PORTAL

resource "awscc_workspacesweb_portal" "main" {

  count = local.environment == "test" ? 1 : 0

  display_name         = "laa-workspaces-web"
  network_settings_arn = awscc_workspacesweb_network_settings.main[0].network_settings_arn
  user_settings_arn    = awscc_workspacesweb_user_settings.main[0].user_settings_arn
}

### USER SETTINGS

# Create a user settings configuration
resource "awscc_workspacesweb_user_settings" "main" {

  count = local.environment == "test" ? 1 : 0

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
    hidden_toolbar_items = ["Microphone", "Webcam"] /* THESE NEED DOING MANUALLY 🤡 */
  }
}
