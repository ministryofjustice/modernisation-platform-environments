locals {
  account_info = {
    business_unit    = var.networking[0].business-unit
    region           = "eu-west-2"
    vpc_id           = data.aws_vpc.shared.id
    application_name = local.application_name
    mp_environment   = local.environment
  }

  db_config_all = {
    ami_name     = "delius_core_ol_8_5_oracle_db_19c_patch_2023-06-12T12-32-07.259Z"
  }
}
