locals {
  project         = local.application_data.accounts[local.environment].project_short_id
  glue_db         = local.application_data.accounts[local.environment].glue_db_name
  description     = local.application_data.accounts[local.environment].db_description
  create_db       = local.application_data.accounts[local.environment].create_database
  glue_job        = local.application_data.accounts[local.environment].glue_job_name
  create_job      = local.application_data.accounts[local.environment].create_job
  create_sec_conf = local.application_data.accounts[local.environment].create_security_conf
  env             = local.environment
  s3_kms_arn      = aws_kms_key.s3.arn


  all_tags = merge(
    local.tags,
    {
      Name = "${local.application_name}"
    }
  )
}

# Glue Database Catalog
module "glue_database" {
  source      = "./modules/glue_database"
  create_db   = local.create_db
  name        = "${local.project}-${local.glue_db}-${local.env}"
  description = local.description
}

# Glue JOB
module "glue_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-${local.glue_job}-${local.env}"
  description                   = local.description
  create_security_configuration = local.create_sec_conf
  tags                          = local.all_tags
  script_location               = "s3://${local.env}/driver.py"
  enable_continuous_log_filter  = false
  project_id                    = local.project
  aws_kms_key                   = local.s3_kms_arn
}

# S3 Demo
module "s3_demo_bucket" {
  source        = "./modules/s3_bucket"
  create_bucket = true
  tags          = local.all_tags
  name          = "${local.project}-demo-${local.env}-"
  aws_kms_arn   = local.s3_kms_arn
}

# S3 Glue Jobs
module "s3_glue_jobs_bucket" {
  source        = "./modules/s3_bucket"
  create_bucket = true
  tags          = local.all_tags
  name_prefix   = "${local.project}-glue-jobs-${local.env}-"
  aws_kms_arn   = local.s3_kms_arn
}

# S3 Landing
module "s3_landing_bucket" {
  source        = "./modules/s3_bucket"
  create_bucket = true
  tags          = local.all_tags
  name_prefix   = "${local.project}-landing-${local.env}-"
  aws_kms_arn   = local.s3_kms_arn
}

# S3 RAW
module "s3_raw_bucket" {
  source        = "./modules/s3_bucket"
  create_bucket = true
  tags          = local.all_tags
  name_prefix   = "${local.project}-raw-${local.env}-"
  aws_kms_arn   = local.s3_kms_arn
}

# S3 Structured
module "s3_structured_bucket" {
  source        = "./modules/s3_bucket"
  create_bucket = true
  tags          = local.all_tags
  name_prefix   = "${local.project}-structured-${local.env}-"
  aws_kms_arn   = local.s3_kms_arn
}

# S3 Curated
module "s3_curated_bucket" {
  source        = "./modules/s3_bucket"
  create_bucket = true
  tags          = local.all_tags
  name_prefix   = "${local.project}-curated-${local.env}-"
  aws_kms_arn   = local.s3_kms_arn
}