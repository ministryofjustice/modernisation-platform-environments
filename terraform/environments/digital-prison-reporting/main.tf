locals {
  project                = local.application_data.accounts[local.environment].project_short_id
  glue_db                = local.application_data.accounts[local.environment].glue_db_name
  glue_db_data_domain    = local.application_data.accounts[local.environment].glue_db_data_domain
  description            = local.application_data.accounts[local.environment].db_description
  create_db              = local.application_data.accounts[local.environment].create_database
  glue_job               = local.application_data.accounts[local.environment].glue_job_name
  create_job             = local.application_data.accounts[local.environment].create_job
  create_sec_conf        = local.application_data.accounts[local.environment].create_security_conf
  env                    = local.environment
  s3_kms_arn             = aws_kms_key.s3.arn
  kinesis_kms_arn        = aws_kms_key.kinesis-kms-key.arn
  kinesis_kms_id         = data.aws_kms_key.kinesis_kms_key.key_id
  create_bucket          = local.application_data.accounts[local.environment].setup_buckets
  account_id             = data.aws_caller_identity.current.account_id
  account_region         = data.aws_region.current.name
  create_kinesis         = local.application_data.accounts[local.environment].create_kinesis_streams
  enable_glue_registry   = local.application_data.accounts[local.environment].create_glue_registries
  setup_buckets          = local.application_data.accounts[local.environment].setup_s3_buckets
  create_glue_connection = local.application_data.accounts[local.environment].create_glue_connections
  image_id               = local.application_data.accounts[local.environment].ami_image_id
  instance_type          = local.application_data.accounts[local.environment].ec2_instance_type
  create_datamart        = local.application_data.accounts[local.environment].setup_redshift
  redshift_cluster_name  = "${local.application_data.accounts[local.environment].project_short_id}-redshift-${local.environment}"


  all_tags = merge(
    local.tags,
    {
      Name = "${local.application_name}"
    }
  )
}

############################
# Federated Cloud Platform # 
############################

# Terraform AWS Glue Database
module "glue_demo_table" {
  source = "./modules/glue_table"
  name   = "${local.project}-glue-demo-table-${local.env}"

  # AWS Glue catalog DB
  enable_glue_catalog_database     = false
  glue_catalog_database_name       = module.glue_database.db_name
  glue_catalog_database_parameters = null

  # AWS Glue catalog table
  enable_glue_catalog_table      = true
  glue_catalog_table_description = "Demo Table resource managed by Terraform."
  glue_catalog_table_table_type  = "EXTERNAL_TABLE"
  glue_catalog_table_parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
    "classification"      = "parquet"
  }
  glue_catalog_table_storage_descriptor = {
    location      = "s3://${module.s3_demo_bucket[0].bucket.id}/demo_table_data"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    columns = [
      {
        columns_name    = "col1"
        columns_type    = "string"
        columns_comment = "col1"
      },
      {
        columns_name    = "col2"
        columns_type    = "double"
        columns_comment = "col2"
      },
      {
        columns_name    = "col3"
        columns_type    = "date"
        columns_comment = ""
      },
    ]

    ser_de_info = [
      {
        name                  = "demo-stream"
        serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

        parameters = {
          "serialization.format" = 1
        }
      }
    ]

    skewed_info = []

    sort_columns = []
  }
  glue_table_depends_on = [module.glue_database.db_name]
}

# kinesis Data Stream Ingestor
module "kinesis_stream_ingestor" {
  source                    = "./modules/kinesis_stream"
  create_kinesis_stream     = local.create_kinesis
  name                      = "${local.project}-kinesis-ingestor-${local.env}"
  shard_count               = 1
  retention_period          = 24
  shard_level_metrics       = ["IncomingBytes", "OutgoingBytes"]
  enforce_consumer_deletion = false
  encryption_type           = "KMS"
  kms_key_id                = local.kinesis_kms_id
  project_id                = local.project

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-kinesis-ingestor-${local.env}"
      Resource_Type = "Kinesis Data Stream"
    }
  )
}

# kinesis Domain Data Stream
module "kinesis_stream_domain_data" {
  source                    = "./modules/kinesis_stream"
  create_kinesis_stream     = local.create_kinesis
  name                      = "${local.project}-kinesis-data-domain-${local.env}"
  shard_count               = 1
  retention_period          = 24
  shard_level_metrics       = ["IncomingBytes", "OutgoingBytes"]
  enforce_consumer_deletion = false
  encryption_type           = "KMS"
  kms_key_id                = local.kinesis_kms_id
  project_id                = local.project

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-kinesis-domain-data-${local.env}"
      Resource_Type = "Kinesis Data Stream"
      Component     = "Domain Data"
    }
  )
}

# kinesis DEMO Data Stream
module "kinesis_stream_demo_data" {
  source                    = "./modules/kinesis_stream"
  create_kinesis_stream     = local.create_kinesis
  name                      = "${local.project}-kinesis-data-demo-${local.env}"
  shard_count               = 1
  retention_period          = 24
  shard_level_metrics       = ["IncomingBytes", "OutgoingBytes"]
  enforce_consumer_deletion = false
  encryption_type           = "KMS"
  kms_key_id                = local.kinesis_kms_id
  project_id                = local.project

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-kinesis-data-demo-${local.env}"
      Resource_Type = "Kinesis Data Stream"
      Component     = "Demo"
    }
  )
}

# Glue Registry
module "glue_registry_avro" {
  source               = "./modules/glue_registry"
  enable_glue_registry = true
  name                 = "${local.project}-glue-registry-avro-${local.env}"
  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-glue-registry-avro-${local.env}"
      Resource_Type = "Glue Registry"
    }
  )
}

# Glue Database Catalog 
module "glue_database" {
  source         = "./modules/glue_database"
  create_db      = local.create_db
  name           = "${local.project}-${local.glue_db}-${local.env}"
  description    = local.description
  aws_account_id = local.account_id
  aws_region     = local.account_region
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
  create_kinesis_ingester       = local.create_kinesis
  additional_policies           = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_read_only_arn
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

##########################
# Data Domain Components # 
##########################

# Glue Database Catalog for Data Domain
module "glue_data_domain_database" {
  source         = "./modules/glue_database"
  create_db      = local.create_db
  name           = "${local.project}-${local.glue_db_data_domain}-${local.env}"
  description    = "Glue Data Catalog for Data Domain Platform"
  aws_account_id = local.account_id
  aws_region     = local.account_region
}

# Data Domain Bucket
module "s3_domain_bucket" {
  count  = local.create_bucket ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix = "${local.project}-domain-${local.env}-"

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
      Name          = "${local.project}-domain-${local.env}-s3"
      Resource_Type = "S3 Bucket"
      Component     = "Data Domain"
    }
  )
}

# Data Domain Configuration Bucket
module "s3_domain_config_bucket" {
  count  = local.create_bucket ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix = "${local.project}-domain-config-${local.env}-"

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
      Name          = "${local.project}-domain-config-${local.env}-s3"
      Resource_Type = "S3 Bucket"
      Component     = "Data Domain"
    }
  )
}

# Data Domain Glue Connection (RedShift)
module "glue_connection_redshift" {
  source            = "./modules/glue_connection"
  create_connection = local.create_glue_connection
  name              = "${local.project}-glue-connect-redshift-${local.env}"
  connection_url    = ""
  description       = "Data Domain, Glue Connection to Redshift"
  security_groups   = []
  availability_zone = ""
  subnet            = ""
  password          = ""
  username          = ""
}

##########################
# Application Backend TF # 
##########################

# S3 Bucket (Terraform State for Application IAAC)
module "s3_application_tf_state" {
  source         = "./modules/s3_bucket"
  create_s3      = local.setup_buckets
  name           = "${local.project}-terraform-state-${local.environment}"
  custom_kms_key = local.s3_kms_arn

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-terraform-state-${local.environment}"
      Resource_Type = "S3 Bucket"
    }
  )
}

# Ec2
module "ec2_kinesis_agent" {
  source                      = "./modules/ec2"
  name                        = "${local.project}-ec2-kinesis-agent-${local.env}"
  description                 = "EC2 instance for kinesis agent"
  vpc                         = data.aws_vpc.shared.id
  cidr                        = [data.aws_vpc.shared.cidr_block]
  subnet_ids                  = data.aws_subnet.private_subnets_a.id
  ec2_instance_type           = local.instance_type
  ami_image_id                = local.image_id
  aws_region                  = local.account_region
  ec2_terminate_behavior      = "terminate"
  associate_public_ip_address = false
  ebs_optimized               = true
  monitoring                  = true
  ebs_size                    = 20
  ebs_encrypted               = true
  ebs_delete_on_termination   = false
  s3_policy_arn               = aws_iam_policy.read_s3_read_access_policy.arn

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-ec2-kinesis-agent-${local.env}"
      Resource_Type = "EC2 Instance"
    }
  )
}

# DataMart
module "datamart" {
  source                  = "./modules/redshift"
  create_redshift_cluster = local.create_datamart
  name                    = local.redshift_cluster_name
  node_type               = "ra3.xlplus"
  number_of_nodes         = 1
  database_name           = "datamart"
  master_username         = "dpruser"
  master_password         = "Datamartpass2022"
  create_random_password  = false
  encrypted               = true
  create_subnet_group     = true
  kms_key_arn             = aws_kms_key.redshift-kms-key.arn
  enhanced_vpc_routing    = false
  subnet_ids              = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  vpc                     = data.aws_vpc.shared.id
  cidr                    = [data.aws_vpc.shared.cidr_block]
  iam_role_arns           = aws_iam_role.redshift-role.[count.index].arn

  # Endpoint access - only available when using the ra3.x type, for S3 Simple Service
  create_endpoint_access = false

  # Scheduled actions
  create_scheduled_action_iam_role = true
  scheduled_actions = {
    pause = {
      name          = "${local.redshift_cluster_name}-pause"
      description   = "Pause cluster every night"
      schedule      = "cron(0 02 * * ? *)"
      pause_cluster = true
    }
    resume = {
      name           = "${local.redshift_cluster_name}-resume"
      description    = "Resume cluster every morning"
      schedule       = "cron(0 08 * * ? *)"
      resume_cluster = true
    }
  }

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.redshift_cluster_name}"
      Resource_Type = "Redshift Cluster"
    }
  )
}