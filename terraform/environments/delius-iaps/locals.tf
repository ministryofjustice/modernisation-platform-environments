#### This file can be used to store locals specific to the member account ####
locals {
  ndelius_interface_params      = yamldecode(file("${path.module}/files/ndelius_interface_ssm_params.yml"))
  iaps_snapshot_data_refresh_id = nonsensitive(tostring(data.aws_ssm_parameter.iaps_snapshot_data_refresh_id.value))
}
