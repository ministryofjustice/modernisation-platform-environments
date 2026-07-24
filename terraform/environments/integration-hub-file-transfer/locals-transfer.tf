locals {
  transfer_subnet_ids = local.is-production ? sort(data.aws_subnets.shared-public.ids) : slice(sort(data.aws_subnets.shared-public.ids), 0, 1)

  transfer_server_users = {
    dms1981 = {
      environments          = ["development"]
      identity_provider_key = "secrets"
      idp_username          = "dms1981"
      home_directory_target = "dms1981"
      server_id_allow_list  = []
      cidr_blocks           = []
      ssh_public_keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPE6XyQIDh5gt+7HOrUQymtsfl3+NZqUM5p7BQqi9uso"
      ]
    }
  }

  environment_transfer_server_users = {
    for username, user in local.transfer_server_users : username => user
    if contains(user.environments, local.environment)
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