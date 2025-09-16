### SECURITY GROUP

module "workspacesweb_security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions


  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name   = "workspacesweb"
  vpc_id = data.aws_vpc.shared.id



  # Flat CIDR rules (Cloud Platform + Microsoft Entra)
  # egress_with_cidr_blocks = concat(
  #   [
  #     {
  #       from_port        = "443"
  #       to_port         = "443"
  #       protocol        = "tcp"
  #       cidr_block  = local.cloud_platform_ranges[0]
  #       description = "Cloud Platform internal (single CIDR)"
  #     }
  #   ],
  #   [
  #     for cidr in local.prefixes_ipv4_unique_sorted : {
  #       from_port        = "443"
  #       to_port         = "443"
  #       protocol        = "tcp"
  #       cidr_block  = cidr
  #       description = "Microsoft Entra SAML auth ${cidr}"
  #     }
  #   ]
  # )

  egress_cidr_blocks = local.cloud_platform_ranges
  egress_rules       = ["https-443-tcp"]
  # egress_prefix_list_ids = [aws_ec2_managed_prefix_list.entra_saml_auth.id]
  egress_with_prefix_list_ids = [
    {
      from_port      = "443"
      to_port        = "443"
      protocol       = "tcp"
      prefix_list_id = [aws_ec2_managed_prefix_list.entra_saml_auth.id]
      description    = "Microsoft Entra SAML auth"

    }

  ]

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

resource "aws_ec2_managed_prefix_list" "entra_saml_auth" {
  name           = "microsoft-entra-saml-auth"
  address_family = "IPv4"
  max_entries    = local.prefix_list_capacity
  tags = {
    ManagedBy = "terraform"
    Source    = "MicrosoftServiceTags"
    Purpose   = "EntraID-SAML-Auth"
  }
}

resource "aws_ec2_managed_prefix_list_entry" "entra_saml_auth_entries" {
  for_each       = { for cidr in local.prefixes_ipv4_unique_sorted : cidr => cidr }
  prefix_list_id = aws_ec2_managed_prefix_list.entra_saml_auth.id
  cidr           = each.value
  description    = "Microsoft Entra SAML auth (AAD + AFD Frontend)"
}