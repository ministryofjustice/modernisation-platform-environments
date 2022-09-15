locals {
    project     = local.application_data.accounts[local.environment].project_short_id
    glue_db     = local.application_data.accounts[local.environment].glue_db_name
    description = local.application_data.accounts[local.environment].db_description
    create_db   = local.application_data.accounts[local.environment].create_database
    glue_job    = local.application_data.accounts[local.environment].glue_job_name
    create_job  = local.application_data.accounts[local.environment].create_job
}

# Glue Database Catalog
module "glue_database" {
  source        = "./modules/glue_database"
  create_db     = "${local.create_db}
  name          = "${local.project}-${local.glue_db}-${local.environment}"
  description   = "${local.description}"
}

# Glue JOB
module "glue_job" {
  source        = "./modules/glue_job"
  create_job    = "${local.create_job}
  name          = "${local.project}-${local.glue_job}-${local.environment}"
  description   = "${local.description}"
}