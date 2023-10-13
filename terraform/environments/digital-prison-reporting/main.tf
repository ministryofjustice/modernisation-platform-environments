###############################################
# Glue Jobs, Reusable Module: /modules/glue_job
###############################################
## Glue Job, Reporting Hub
## Glue Cloud Platform Ingestion Job (Load, Reload, CDC)
locals {
  glue_avro_registry = split("/", module.glue_registry_avro.registry_name)
}

module "glue_reporting_hub_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-reporting-hub-${local.env}"
  short_name                    = "${local.project}-reporting-hub"
  description                   = local.description
  command_type                  = "gluestreaming"
  job_language                  = "scala"
  create_security_configuration = local.create_sec_conf
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-reporting-hub-${local.env}/"
  # Using s3a for checkpoint because to align with Hadoop 3 supports
  checkpoint_dir                = "s3a://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.project}-reporting-hub-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-reporting-hub-${local.env}/"
  # Placeholder Script Location
  script_location               = local.glue_placeholder_script_location
  enable_continuous_log_filter  = false
  project_id                    = local.project
  aws_kms_key                   = local.s3_kms_arn
  additional_policies           = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
  execution_class               = "STANDARD"
  worker_type                   = local.reporting_hub_worker_type
  number_of_workers             = local.reporting_hub_num_workers
  max_concurrent                = 1
  region                        = local.account_region
  account                       = local.account_id
  log_group_retention_in_days   = 1

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-reporting-hub-${local.env}"
      Resource_Type = "Glue Job"
      Jira          = "DPR-265"
    }
  )

  arguments = {
    "--extra-jars"                          = local.glue_jobs_latest_jar_location
    "--job-bookmark-option"                 = "job-bookmark-disable"
    "--class"                               = "uk.gov.justice.digital.job.DataHubJob"
    "--dpr.kinesis.stream.arn"              = module.kinesis_stream_ingestor.kinesis_stream_arn
    "--dpr.aws.region"                      = local.account_region
    "--dpr.curated.s3.path"                 = "s3://${module.s3_curated_bucket.bucket_id}/"
    "--dpr.batchDurationSeconds"            = local.reporting_hub_batch_duration_seconds
    "--dpr.add.idle.time.between.reads"     = local.reporting_hub_add_idle_time_between_reads
    "--dpr.idle.time.between.reads.millis"  = local.reporting_hub_idle_time_between_reads_in_millis
    "--dpr.datastorage.retry.maxAttempts"   = local.reporting_hub_retry_max_attempts
    "--dpr.datastorage.retry.minWaitMillis" = local.reporting_hub_retry_min_wait_millis
    "--dpr.datastorage.retry.maxWaitMillis" = local.reporting_hub_retry_max_wait_millis
    "--dpr.raw.s3.path"                     = "s3://${module.s3_raw_bucket.bucket_id}/"
    "--dpr.structured.s3.path"              = "s3://${module.s3_structured_bucket.bucket_id}/"
    "--dpr.violations.s3.path"              = "s3://${module.s3_violation_bucket.bucket_id}/"
    "--enable-metrics"                      = true
    "--enable-spark-ui"                     = false
    "--enable-auto-scaling"                 = true
    "--enable-job-insights"                 = true
    "--dpr.aws.dynamodb.endpointUrl"        = "https://dynamodb.${local.account_region}.amazonaws.com"
    "--dpr.contract.registryName"           = trimprefix(module.glue_registry_avro.registry_name, "${local.glue_avro_registry[0]}/")
    "--dpr.domain.registry"                 = "${local.project}-domain-registry-${local.environment}"
    "--dpr.domain.target.path"              = "s3://${module.s3_domain_bucket.bucket_id}"
    "--dpr.domain.catalog.db"               = module.glue_data_domain_database.db_name
    "--dpr.redshift.secrets.name"           = "${local.project}-redshift-secret-${local.environment}"
    "--dpr.datamart.db.name"                = "datamart"
    "--dpr.log.level"                       = local.reporting_hub_log_level
  }
}

# Glue Job, Domain Refresh
module "glue_domain_refresh_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-domain-refresh-${local.env}"
  short_name                    = "${local.project}-domain-refresh"
  command_type                  = "glueetl"
  description                   = "Monitors the reporting hub for table changes and applies them to domains"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-domain-refresh-${local.env}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.project}-domain-refresh-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-domain-refresh-${local.env}/"
  # Placeholder Script Location
  script_location               = local.glue_placeholder_script_location
  enable_continuous_log_filter  = false
  project_id                    = local.project
  aws_kms_key                   = local.s3_kms_arn
  additional_policies           = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
  # timeout                       = 1440
  execution_class               = "FLEX"
  worker_type                   = local.refresh_job_worker_type
  number_of_workers             = local.refresh_job_num_workers
  max_concurrent                = 64
  region                        = local.account_region
  account                       = local.account_id
  log_group_retention_in_days   = 1

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-domain-refresh-${local.env}"
      Resource_Type = "Glue Job"
      Jira          = "DPR-265"
    }
  )

  arguments = {
    "--extra-jars"                   = local.glue_jobs_latest_jar_location
    "--class"                        = "uk.gov.justice.digital.job.DomainRefreshJob"
    "--datalake-formats"             = "delta"
    "--dpr.aws.dynamodb.endpointUrl" = "https://dynamodb.${local.account_region}.amazonaws.com"
    "--dpr.aws.kinesis.endpointUrl"  = "https://kinesis.${local.account_region}.amazonaws.com"
    "--dpr.aws.region"               = local.account_region
    "--dpr.curated.s3.path"          = "s3://${module.s3_curated_bucket.bucket_id}"
    "--dpr.domain.registry"          = "${local.project}-domain-registry-${local.environment}"
    "--dpr.domain.target.path"       = "s3://${module.s3_domain_bucket.bucket_id}"
    "--dpr.domain.catalog.db"        = module.glue_data_domain_database.db_name
    "--dpr.log.level"                = local.refresh_job_log_level
  }
}

# kinesis Data Stream Ingestor
module "kinesis_stream_ingestor" {
  source                    = "./modules/kinesis_stream"
  create_kinesis_stream     = local.create_kinesis
  name                      = local.kinesis_stream_ingestor
  shard_count               = 1 # Not Valid when ON-DEMAND Mode
  retention_period          = local.kinesis_retention_hours
  shard_level_metrics       = ["IncomingBytes", "OutgoingBytes"]
  enforce_consumer_deletion = false
  encryption_type           = "KMS"
  kms_key_id                = local.kinesis_kms_id
  project_id                = local.project

  tags = merge(
    local.all_tags,
    {
      Name          = local.kinesis_stream_ingestor
      Resource_Type = "Kinesis Data Stream"
    }
  )
}

module "kinesis_stream_reconciliation_firehose_s3" {
  source                     = "./modules/kinesis_firehose"
  name                       = "reconciliation-${module.kinesis_stream_ingestor.kinesis_stream_name}"
  aws_account_id             = local.account_id
  aws_region                 = local.account_region
  cloudwatch_log_group_name  = "/aws/kinesisfirehose/reconciliation-${module.kinesis_stream_ingestor.kinesis_stream_name}"
  cloudwatch_log_stream_name = "DestinationDelivery"
  cloudwatch_logging_enabled = false
  kinesis_source_stream_arn  = module.kinesis_stream_ingestor.kinesis_stream_arn
  kinesis_source_stream_name = module.kinesis_stream_ingestor.kinesis_stream_name
  target_s3_arn              = module.s3_working_bucket.bucket_arn
  target_s3_id               = module.s3_working_bucket.bucket_id
  target_s3_prefix           = "reconciliation/${module.kinesis_stream_ingestor.kinesis_stream_name}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
  target_s3_error_prefix     = "reconciliation/${module.kinesis_stream_ingestor.kinesis_stream_name}-error/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}"
  target_s3_kms              = local.s3_kms_arn
  buffering_size             = 128
  buffering_interval         = 900
  database_name              = module.glue_reconciliation_database.db_name
  table_name                 = module.glue_reconciliation_table.table_name
}

# Glue Registry
module "glue_registry_avro" {
  source               = "./modules/glue_registry"
  enable_glue_registry = true
  name                 = "${local.project}-glue-registry-avro-${local.env}"
  tags                 = merge(
    local.all_tags,
    {
      Name          = "${local.project}-glue-registry-avro-${local.env}"
      Resource_Type = "Glue Registry"
    }
  )
}

###################################################
# Glue Tables, Reusable Module: /modules/glue_table
###################################################

## Glue Table, RAW
module "glue_raw_table" {
  source                    = "./modules/glue_table"
  enable_glue_catalog_table = true
  name                      = "raw"

  # AWS Glue catalog DB
  glue_catalog_database_name       = module.glue_raw_zone_database.db_name
  glue_catalog_database_parameters = null

  # AWS Glue catalog table
  glue_catalog_table_description = "Glue Table for raw data, managed by Terraform."
  glue_catalog_table_table_type  = "EXTERNAL_TABLE"
  glue_catalog_table_parameters  = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
    "classification"      = "parquet"
  }
  glue_catalog_table_storage_descriptor = {
    location      = "s3://${module.s3_raw_bucket.bucket_id}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    columns = [
      {
        columns_name    = "partitionkey"
        columns_type    = "string"
        columns_comment = "Partition Key"
      },
      {
        columns_name    = "sequencenumber"
        columns_type    = "string"
        columns_comment = "Sequence Number"
      },
      {
        columns_name    = "approximatearrivaltimestamp"
        columns_type    = "timestamp"
        columns_comment = "Arrival Timestamp"
      },
      {
        columns_name    = "data"
        columns_type    = "string"
        columns_comment = "Data Column"
      },
    ]

    ser_de_info = [
      {
        serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

        parameters = {
          "serialization.format" = 1
        }
      }
    ]

    skewed_info = []

    sort_columns = []
  }
  glue_table_depends_on = [module.glue_raw_zone_database.db_name]
}

module "glue_reconciliation_table" {
  source                    = "./modules/glue_table"
  enable_glue_catalog_table = true
  name                      = "reconciliation-${module.kinesis_stream_ingestor.kinesis_stream_name}"

  # AWS Glue catalog DB
  glue_catalog_database_name       = module.glue_reconciliation_database.db_name
  glue_catalog_database_parameters = null

  # AWS Glue catalog table
  glue_catalog_table_description = "Glue Table for reconciliation data, managed by Terraform."
  glue_catalog_table_table_type  = "EXTERNAL_TABLE"
  glue_catalog_table_parameters  = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
    "classification"      = "parquet"
  }
  glue_catalog_table_storage_descriptor = {

    location      = "s3://${module.s3_working_bucket.bucket_id}/reconciliation/${module.kinesis_stream_ingestor.kinesis_stream_name}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    columns = [
      {
        columns_name    = "data"
        columns_type    = "string"
        columns_comment = "Nested JSON data"
      },
      {
        columns_name    = "metadata"
        columns_type    = "string"
        columns_comment = "Common metadata"
      }
    ]

    partition_keys = [
      {
        name    = "year",
        type    = "string",
        comment = ""
      },
      {
        name    = "month",
        type    = "string",
        comment = ""
      },
      {
        name    = "day",
        type    = "string",
        comment = ""
      }
    ]

    ser_de_info = [
      {
        serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

        parameters = {
          "serialization.format" = 1
        }
      }
    ]

    skewed_info = []

    sort_columns = []
  }
  glue_table_depends_on = [module.glue_reconciliation_database.db_name]
}


##################
### S3 Buckets ###
##################
# S3 Glue Jobs
module "s3_glue_job_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-glue-jobs-${local.environment}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-glue-jobs-${local.environment}"
      Resource_Type = "S3 Bucket"
    }
  )
}

# S3 Landing
module "s3_landing_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-landing-${local.env}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true

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
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-raw-zone-${local.env}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-raw-zone-${local.env}"
      Resource_Type = "S3 Bucket"
    }
  )
}

# S3 Structured
module "s3_structured_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-structured-zone-${local.env}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-structured-zone-${local.env}"
      Resource_Type = "S3 Bucket"
    }
  )
}

# S3 Curated
module "s3_curated_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-curated-zone-${local.env}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-curated-zone-${local.env}"
      Resource_Type = "S3 Bucket"
    }
  )
}

# Data Domain Bucket
module "s3_domain_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-domain-${local.env}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-domain-${local.env}"
      Resource_Type = "S3 Bucket"
    }
  )
}

# Data Domain Configuration Bucket
module "s3_domain_config_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-domain-config-${local.env}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-domain-config-${local.env}"
      Resource_Type = "S3 Bucket"
    }
  )
}

# S3 Violation Zone Bucket, DPR-318/DPR-301
module "s3_violation_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-violation-${local.environment}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-violation-${local.environment}"
      Resource_Type = "S3 Bucket"
    }
  )
}

# S3 Bucket (Application Artifacts Store)
module "s3_artifacts_store" {
  source              = "./modules/s3_bucket"
  create_s3           = local.setup_buckets
  name                = "${local.project}-artifact-store-${local.environment}"
  custom_kms_key      = local.s3_kms_arn
  enable_notification = true #

  # Dynamic, supports multiple notifications blocks
  bucket_notifications = {
    "lambda_function_arn" = "${module.domain_builder_flyway_Lambda.lambda_function}"
    "events"              = ["s3:ObjectCreated:*"]
    "filter_prefix"       = "build-artifacts/domain-builder/jars/"
    "filter_suffix"       = ".jar"
  }

  dependency_lambda = [module.domain_builder_flyway_Lambda.lambda_function] # Required if bucket_notications is enabled

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-artifact-store-${local.environment}"
      Resource_Type = "S3 Bucket"
    }
  )
}

# S3 Violation Zone Bucket, DPR-408
module "s3_working_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-working-${local.environment}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-working-${local.environment}"
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
  name           = "domain"
  description    = "Glue Data Catalog - Domain Data"
  aws_account_id = local.account_id
  aws_region     = local.account_region
}

# Glue Database Catalog for Data Domain
module "glue_raw_zone_database" {
  source         = "./modules/glue_database"
  create_db      = local.create_db
  name           = "raw"
  description    = "Glue Data Catalog - Raw Zone"
  aws_account_id = local.account_id
  aws_region     = local.account_region
}

# Glue Database Catalog for Data Domain
module "glue_structured_zone_database" {
  source         = "./modules/glue_database"
  create_db      = local.create_db
  name           = "structured"
  description    = "Glue Data Catalog - Structured Zone"
  aws_account_id = local.account_id
  aws_region     = local.account_region
}

# Glue Database Catalog for Data Domain
module "glue_curated_zone_database" {
  source         = "./modules/glue_database"
  create_db      = local.create_db
  name           = "curated"
  description    = "Glue Data Catalog - Curated Zone"
  aws_account_id = local.account_id
  aws_region     = local.account_region
}

# Glue Database Catalog for Reconciliation
module "glue_reconciliation_database" {
  source         = "./modules/glue_database"
  create_db      = local.create_db
  name           = "reconciliation"
  description    = "Glue Data Catalog - Reconciliation"
  aws_account_id = local.account_id
  aws_region     = local.account_region
}

#########################################
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
  password          = "" ## Needs to pull from Secrets Manager, #TD
  username          = ""
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
  # s3_policy_arn               = aws_iam_policy.read_s3_read_access_policy.arn # TBC
  region                      = local.account_region
  account                     = local.account_id
  env                         = local.env


  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-ec2-kinesis-agent-${local.env}"
      Resource_Type = "EC2 Instance"
    }
  )
}

# Redhsift Cluster, DataMart
module "datamart" {
  source                  = "./modules/redshift"
  project_id              = local.project
  env                     = local.environment
  create_redshift_cluster = local.create_datamart
  name                    = local.redshift_cluster_name
  node_type               = "ra3.xlplus"
  number_of_nodes         = 1
  database_name           = "datamart"
  master_username         = "dpruser"
  create_random_password  = true
  random_password_length  = 16
  encrypted               = true
  publicly_accessible     = false
  create_subnet_group     = true
  kms_key_arn             = aws_kms_key.redshift-kms-key.arn
  enhanced_vpc_routing    = false
  subnet_ids              = [
    data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id
  ]
  vpc                     = data.aws_vpc.shared.id
  cidr                    = [data.aws_vpc.shared.cidr_block, local.cloud_platform_cidr]
  iam_role_arns           = [aws_iam_role.redshift-role.arn, aws_iam_role.redshift-spectrum-role.arn]

  # Endpoint access - only available when using the ra3.x type, for S3 Simple Service
  create_endpoint_access = false

  # Scheduled actions
  create_scheduled_action_iam_role = true
  scheduled_actions                = {
    pause = {
      name          = "${local.redshift_cluster_name}-pause"
      description   = "Pause cluster every night"
      schedule      = "cron(30 20 * * ? *)"
      pause_cluster = true
    }
    resume = {
      name           = "${local.redshift_cluster_name}-resume"
      description    = "Resume cluster every morning"
      schedule       = "cron(30 07 * * ? *)"
      resume_cluster = true
    }
  }

  logging = {
    enable               = true
    log_destination_type = "cloudwatch"
    retention_period     = 1
    log_exports          = ["useractivitylog", "userlog", "connectionlog"]
  }

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.redshift_cluster_name}"
      Resource_Type = "Redshift Cluster"
    }
  )
}

# DMS Nomis Data Collector
module "dms_nomis_ingestor" {
  source                       = "./modules/dms"
  setup_dms_instance           = local.setup_dms_instance      # Disable all DMS Resources
  enable_replication_task      = local.enable_replication_task # Disable Replication Task
  name                         = "${local.project}-dms-nomis-ingestor-${local.env}"
  vpc_cidr                     = [data.aws_vpc.shared.cidr_block]
  source_engine_name           = "oracle"
  source_db_name               = jsondecode(data.aws_secretsmanager_secret_version.nomis.secret_string)["db_name"]
  source_app_username          = jsondecode(data.aws_secretsmanager_secret_version.nomis.secret_string)["user"]
  source_app_password          = jsondecode(data.aws_secretsmanager_secret_version.nomis.secret_string)["password"]
  source_address               = jsondecode(data.aws_secretsmanager_secret_version.nomis.secret_string)["endpoint"]
  source_db_port               = jsondecode(data.aws_secretsmanager_secret_version.nomis.secret_string)["port"]
  vpc                          = data.aws_vpc.shared.id
  kinesis_stream_policy        = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
  project_id                   = local.project
  env                          = local.environment
  dms_source_name              = "oracle"
  dms_target_name              = "kinesis"
  short_name                   = "nomis"
  migration_type               = "full-load-and-cdc"
  replication_instance_version = "3.4.7" # Upgrade
  replication_instance_class   = "dms.t3.medium"
  subnet_ids                   = [
    data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id
  ]

  vpc_role_dependency        = [aws_iam_role.dmsvpcrole]
  cloudwatch_role_dependency = [aws_iam_role.dms_cloudwatch_logs_role]

  extra_attributes = "supportResetlog=TRUE"

  kinesis_settings = {
    "include_null_and_empty"         = "true"
    "partition_include_schema_table" = "true"
    "include_partition_value"        = "true"
    "kinesis_target_stream"          = "arn:aws:kinesis:eu-west-2:${data.aws_caller_identity.current.account_id}:stream/${local.kinesis_stream_ingestor}"
  }

  availability_zones = {
    0 = "eu-west-2a"
  }

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-dms-t3nomis-ingestor-${local.env}"
      Resource_Type = "DMS Replication"
      Nomis_Source  = "T3"
    }
  )
}

module "dms_fake_data_ingestor" {
  source                       = "./modules/dms"
  setup_dms_instance           = local.setup_fake_data_dms_instance
  enable_replication_task      = local.enable_fake_data_replication_task # Disable Replication Task
  name                         = "${local.project}-dms-fake-data-ingestor-${local.env}"
  vpc_cidr                     = [data.aws_vpc.shared.cidr_block]
  source_engine_name           = "postgres"
  source_db_name               = "db59b5cf9e5de6b794"
  source_app_username          = "cp9Zr5bLim"
  source_app_password          = "whkthrI65zpcFEe5"
  source_address               = "cloud-platform-59b5cf9e5de6b794.cdwm328dlye6.eu-west-2.rds.amazonaws.com"
  source_db_port               = 5432
  vpc                          = data.aws_vpc.shared.id
  kinesis_stream_policy        = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
  project_id                   = local.project
  env                          = local.environment
  dms_source_name              = "postgres"
  dms_target_name              = "kinesis"
  short_name                   = "fake-data"
  migration_type               = "full-load-and-cdc"
  replication_instance_version = "3.4.7" # Rollback
  replication_instance_class   = "dms.t3.medium"
  subnet_ids                   = [
    data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id
  ]

  vpc_role_dependency        = [aws_iam_role.dmsvpcrole]
  cloudwatch_role_dependency = [aws_iam_role.dms_cloudwatch_logs_role]

  kinesis_settings = {
    "include_null_and_empty"         = "true"
    "partition_include_schema_table" = "true"
    "include_partition_value"        = "true"
    "kinesis_target_stream"          = "arn:aws:kinesis:eu-west-2:${data.aws_caller_identity.current.account_id}:stream/${local.kinesis_stream_ingestor}"
  }

  availability_zones = {
    0 = "eu-west-2a"
  }

  tags = merge(
    local.all_tags,
    {
      Name            = "${local.project}-dms-fake-data-ingestor-${local.env}"
      Resource_Type   = "DMS Replication"
      Postgres_Source = "DPS"
    }
  )
}

# Dynamo DB Tables
# Dynamo DB for DomainRegistry, DPR-306/DPR-218
module "dynamo_tab_domain_registry" {
  source              = "./modules/dynamo_tables"
  create_table        = true
  autoscaling_enabled = false
  name                = "${local.project}-domain-registry-${local.environment}"

  hash_key    = "primaryId"
  range_key   = "secondaryId"
  table_class = "STANDARD"
  ttl_enabled = false

  attributes = [
    {
      name = "primaryId"
      type = "S"
    },
    {
      name = "secondaryId"
      type = "S"
    },
    {
      name = "type"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      name            = "primaryId-type-index"
      hash_key        = "primaryId"
      range_key       = "type"
      write_capacity  = 10
      read_capacity   = 10
      projection_type = "ALL"
    },
    {
      name            = "secondaryId-type-index"
      hash_key        = "secondaryId"
      range_key       = "type"
      write_capacity  = 10
      read_capacity   = 10
      projection_type = "ALL"
    }
  ]

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-domain-registry-${local.environment}"
      Resource_Type = "Dynamo Table"
    }
  )
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

# Dynamo Tab for Application TF State 
module "dynamo_tab_application_tf_state" {
  source              = "./modules/dynamo_tables"
  create_table        = true
  autoscaling_enabled = false
  name                = "${local.project}-terraform-state-${local.environment}"

  hash_key    = "LockID" # Hash
  range_key   = ""       # Sort
  table_class = "STANDARD"
  ttl_enabled = false

  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-terraform-state-${local.environment}"
      Resource_Type = "Dynamo Table"
    }
  )
}
