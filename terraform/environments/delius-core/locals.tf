#### This file can be used to store locals specific to the member account ####
locals {
  db_port = 1521

  delius_environments_per_account = {
    # account = [env1, env2]
    prod     = ["prod"]
    pre_prod = ["stage", "preprod"]
    test     = ["test"]
    dev      = ["dev", "poc"]
  }

  ordered_subnet_ids = [data.aws_subnets.shared-private-a.ids[0], data.aws_subnets.shared-private-b.ids[0], data.aws_subnets.shared-private-c.ids[0]]

  # Define a mapping of delius_environments to DMS configuration for that environment.  We include the ID of the AWS
  # account which hosts that particular delius_environment.
  env_name_to_dms_config_map = {
    "dev"     = merge({ dms_config = local.dms_config_dev }, { account_id = try(local.environment_management.account_ids["delius-core-development"], null) })
    "test"    = merge({ dms_config = local.dms_config_test }, { account_id = try(local.environment_management.account_ids["delius-core-test"], null) })
    "stage"   = merge({ dms_config = local.dms_config_stage }, { account_id = try(local.environment_management.account_ids["delius-core-preproduction"], null) })
    "preprod" = merge({ dms_config = local.dms_config_preprod }, { account_id = try(local.environment_management.account_ids["delius-core-preproduction"], null) })
  }
}
