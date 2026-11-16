module "equip_workspaces" {
  source = "./modules/workspaces"
  count  = local.deploy_workspaces ? 1 : 0

  application_name = local.application_name
  environment      = local.environment

  vpc_id     = try(local.application_data.accounts[local.environment].vpc_id, data.aws_vpc.shared.id)
  subnet_ids = try(local.application_data.accounts[local.environment].subnet_ids, [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id])

  domain_name              = local.application_data.accounts[local.environment].domain_name
  ad_connector_size        = local.application_data.accounts[local.environment].ad_connector_size
  ad_connector_username    = local.application_data.accounts[local.environment].ad_connector_username
  ad_connector_password    = jsondecode(data.aws_secretsmanager_secret_version.ad_connector_password[0].secret_string)["Service Account Password"]
  ad_connector_description = try(local.application_data.accounts[local.environment].ad_connector_description, "")
  dns_ips                  = local.application_data.accounts[local.environment].dns_ips
  default_ou               = local.application_data.accounts[local.environment].default_ou

  bundle_id         = local.application_data.accounts[local.environment].bundle_id
  running_mode      = local.application_data.accounts[local.environment].running_mode
  auto_stop_timeout = local.application_data.accounts[local.environment].auto_stop_timeout

  ip_group_allowed_cidrs      = local.application_data.accounts[local.environment].ip_group_allowed_cidrs
  ip_group_name               = try(local.application_data.accounts[local.environment].ip_group_name, "")
  ip_group_description        = try(local.application_data.accounts[local.environment].ip_group_description, "")
  security_group_name         = try(local.application_data.accounts[local.environment].security_group_name, "")
  security_group_description  = try(local.application_data.accounts[local.environment].security_group_description, "")
  security_group_vpc_id       = try(local.application_data.accounts[local.environment].security_group_vpc_id, "")
  security_group_egress_rules = try(local.application_data.accounts[local.environment].security_group_egress_rules, [])
  workspace_users             = local.application_data.accounts[local.environment].workspace_users

  create_service_role = false

  tags = local.tags
}
