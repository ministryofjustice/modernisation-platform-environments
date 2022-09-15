locals {
    project         = local.application_data.accounts[local.environment].project_short_id
    glue_db         = local.application_data.accounts[local.environment].glue_db_name
    description     = local.application_data.accounts[local.environment].db_description
    create_db       = local.application_data.accounts[local.environment].create_database
    glue_job        = local.application_data.accounts[local.environment].glue_job_name
    create_job      = local.application_data.accounts[local.environment].create_job
    create_sec_conf = local.application_data.accounts[local.environment].create_security_conf


    all_tags = merge(
        local.tags,
        {
        Name = "${local.application_name}"
        }
    )    
}

# Glue Database Catalog
module "glue_database" {
  source        = "./modules/glue_database"
  create_db     = "${local.create_db}
  name          = "${local.project}-${local.glue_db}-${local.environment}"
  description   = local.description
  tags          = local.all_tags
}

# Glue JOB
module "glue_job" {
  source                        = "./modules/glue_job"
  create_job                    = "${local.create_job}
  name                          = "${local.project}-${local.glue_job}-${local.environment}"
  description                   = "${local.description}"
  create_security_configuration = "${local.create_sec_conf}"
  tags                          = local.all_tags
  script_location               = "s3://${var.bucket}/${var.environment}/driver.py"
  enable_continuous_log_filter  = false
}