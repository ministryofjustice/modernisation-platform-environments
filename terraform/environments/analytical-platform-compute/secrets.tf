module "actions_runners_create_a_derived_table_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.1.2"

  name        = "actions-runners/create-a-derived-table"
  description = "moj-data-platform-robot: https://github.com/settings/personal-access-tokens/2208432"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    {
      "expiry-date" = "2024-10-26"
    }
  )
}

moved {
  from = module.actions_runners_create_a_derived_table
  to   = module.actions_runners_create_a_derived_table_secret
}
