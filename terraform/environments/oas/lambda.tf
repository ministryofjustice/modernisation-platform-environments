# Commenting this rotation lambda out as it is currently not required

# module "rotate_secrets_lambda" {
#   source = "./modules/rotate_secrets_lambda"
#
#   region                      = local.application_data.accounts[local.environment].region
#   lambda_timeout              = 300
#   lambda_runtime              = "python3.8"
#   database_name = "lambdadb"  # TODO Is this variable still actually used?
#   database_user = "admin" # TODO Is this variable still actually used?
#   log_group_retention_days = local.application_data.accounts[local.environment].rotate_secret_lambda_retention
#   tags                             = local.tags
#   account_number                   = local.environment_management.account_ids[terraform.workspace]
# }
