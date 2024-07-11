################################################################################
# Example, Operational DB - Transfer Component Role/User
################################################################################

# locals {
#      transfer_component_role_credentials = jsondecode(data.aws_secretsmanager_secret_version.transfer_component_role_secret_version.secret_string)
# }


# module "transfer_component_role" {
#   source = "./modules/rds/rds-pgres-role/"
#
#   setup_additional_users = false
#   host                   = module.aurora_operational_db.rds_cluster_endpoints["static"]
#   port                   = 5432
#   database               = "postgres"
#   db_username            = local.operational_db_credentials.username
#   db_master_password     = local.operational_db_credentials.password
#   db_password            = local.transfer_component_role_credentials.password
#   rds_role_name          = local.transfer_component_role_credentials.username
#   read_write_role        = true
# }
