locals {
  transfer_subnet_ids = local.is-production ? sort(data.aws_subnets.shared-public.ids) : slice(sort(data.aws_subnets.shared-public.ids), 0, 1)

  transfer_server_users = {
    dms1981 = {
      environments   = ["development"]
      ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPE6XyQIDh5gt+7HOrUQymtsfl3+NZqUM5p7BQqi9uso"
      cidr_blocks    = []
    }
  }

  transfer_user_cidr_blocks = {
    for username, user in local.transfer_server_users : username => user.cidr_blocks
    if length(user.cidr_blocks) > 0
    && contains(user.environments, local.environment)
  }
}