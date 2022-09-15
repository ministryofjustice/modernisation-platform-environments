locals {
    project = local.application_data.accounts[local.environment].project_short_id
}

#######################
# Glue Database Catalog
#######################
module "glue_database" {
  source = "./modules/glue_database"

  create = local.application_data.accounts[local.environment].create_database

  name = local.application_data.accounts[local.environment].glue_db_name

  description = local.application_data.accounts[local.environment].db_description
}
