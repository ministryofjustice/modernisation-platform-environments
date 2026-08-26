#### This file can be used to store data specific to the member account ####

data "aws_ssm_parameter" "iaps_snapshot_data_refresh_id" {
  name = "/iaps/snapshot_id"
}
