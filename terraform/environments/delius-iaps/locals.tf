#### This file can be used to store locals specific to the member account ####
locals {
  ndelius_interface_params      = yamldecode(file("${path.module}/files/ndelius_interface_ssm_params.yml"))
  iaps_snapshot_data_refresh_id = nonsensitive(tostring(data.aws_ssm_parameter.iaps_snapshot_data_refresh_id.value))
  oem_account_id                = local.environment_management.account_ids[join("-", ["hmpps-oem", local.environment])]
  dba_secret_name               = format("%s-%s-%s", local.application_name, local.application_data.accounts[local.environment].short_environment_name, "oracle-db-dba-passwords")  #"/delius-iaps-preprod-oracle-db-dba-passwords"
}
