locals {
  transfer_address_allocation_ids = [for key, value in aws_eip.this : value.id]
  transfer_subnet_ids             = local.is-production ? sort(module.vpc_isolated.public_subnets) : slice(sort(module.vpc_isolated.public_subnets), 0, 1)

  legacy_transfer_configuration = jsondecode(file("${path.module}/configuration/${local.environment}/legacy-transfer-applications.json"))

  environment_transfer_server_users = {
    for username, user in local.legacy_transfer_configuration.applications : username => user
    if user.enabled
  }

  transfer_user_cidr_blocks = {
    for username, user in local.environment_transfer_server_users : username => user.cidr_blocks
    if length(user.cidr_blocks) > 0
  }

  custom_idp_configuration = {
    log_level           = "INFO"
    secret_prefix       = "${local.application_name}/${local.environment}/transfer-users/"
    user_name_delimiter = "@@"
  }
}