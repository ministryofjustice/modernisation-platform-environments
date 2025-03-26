#### This file can be used to store locals specific to the member account ####
locals {
  all_cidr_blocks = flatten(concat(
    [for user in values(local.environment_configuration.transfer_server_sftp_users) : user.cidr_blocks],
    [for user in values(local.environment_configuration.transfer_server_sftp_users_with_egress) : user.cidr_blocks]
  ))
}
