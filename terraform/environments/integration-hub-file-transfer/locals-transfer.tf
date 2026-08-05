locals {
  transfer_address_allocation_ids = [for key, value in aws_eip.this : value.id]
  transfer_subnet_ids             = local.is-production ? sort(module.vpc_isolated.public_subnets) : slice(sort(module.vpc_isolated.public_subnets), 0, 1)

  # Custom IdP user configuration. Add users by username and list every
  # environment in which they may authenticate. Terraform creates the initial
  # authentication record in Secrets Manager.
  #
  # environments          - environments in which Terraform creates the user
  # server_id_allow_list  - Transfer server IDs permitted for the user; empty allows any
  # cidr_blocks           - source networks permitted by the security group and IdP;
  #                         empty creates no ingress rules
  # ssh_public_keys       - public keys written to the user's Secrets Manager secret
  #
  # Passwords are deliberately not configured here. Populate the password field
  # directly in the generated Secrets Manager secret when password access is needed.
  transfer_server_users = {
    dms1981 = {
      environments         = ["development"]
      server_id_allow_list = []
      cidr_blocks          = []
      ssh_public_keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPE6XyQIDh5gt+7HOrUQymtsfl3+NZqUM5p7BQqi9uso"
      ]
    }
  }

  environment_transfer_server_users = {
    for username, user in local.transfer_server_users : lower(username) => user
    if contains(user.environments, local.environment)
  }

  transfer_user_cidr_blocks = {
    for username, user in local.environment_transfer_server_users : username => user.cidr_blocks
    if length(user.cidr_blocks) > 0
  }

  custom_idp_configuration = {
    log_level     = "INFO"
    secret_prefix = "${local.application_name}/${local.environment}/transfer-users/"
  }
}