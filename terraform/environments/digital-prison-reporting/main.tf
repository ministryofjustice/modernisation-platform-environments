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
  create_bucket   = local.application_data.accounts[local.environment].setup_buckets


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
  script_location               = "s3://dpr-glue-jobs-development-20220916083016134900000005/scripts/injector.py"
  enable_continuous_log_filter  = false
  project_id                    = local.project
  aws_kms_key                   = local.s3_kms_arn
}

# S3 Demo
module "s3_demo_bucket" {
  count  = local.create_bucket ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  force_destroy = true

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix = "${local.project}-demo-${local.env}-"

  replication_enabled = false
  custom_kms_key      = local.s3_kms_arn

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Disabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      prevent_destroy = false


      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-demo-${local.env}-s3"
      Resource_Type = "S3 Bucket"
    }
  )

}



# S3 Glue Jobs
module "s3_glue_jobs_bucket" {
  count  = local.create_bucket ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix = "${local.project}-glue-jobs-${local.env}-"

  replication_enabled = false
  custom_kms_key      = local.s3_kms_arn
  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-glue-jobs-${local.env}-s3"
      Resource_Type = "S3 Bucket"
    }
  )

}

# S3 Landing
module "s3_landing_bucket" {
  count  = local.create_bucket ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix = "${local.project}-landing-${local.env}-"

  replication_enabled = false
  custom_kms_key      = local.s3_kms_arn
  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-landing-${local.env}-s3"
      Resource_Type = "S3 Bucket"
    }
  )

}

# S3 RAW
module "s3_raw_bucket" {
  count  = local.create_bucket ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix = "${local.project}-raw-${local.env}-"

  replication_enabled = false
  custom_kms_key      = local.s3_kms_arn
  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-raw-${local.env}-s3"
      Resource_Type = "S3 Bucket"
    }
  )

}

# S3 Structured
module "s3_structured_bucket" {
  count  = local.create_bucket ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix = "${local.project}-structured-${local.env}-"

  replication_enabled = false
  custom_kms_key      = local.s3_kms_arn
  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-structured-${local.env}-s3"
      Resource_Type = "S3 Bucket"
    }
  )

}

# S3 Curated
module "s3_curated_bucket" {
  count  = local.create_bucket ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix = "${local.project}-curated-${local.env}-"

  replication_enabled = false
  custom_kms_key      = local.s3_kms_arn
  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-curated-${local.env}-s3"
      Resource_Type = "S3 Bucket"
    }
  )
}