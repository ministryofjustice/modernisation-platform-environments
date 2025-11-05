###############################################
# Glue Jobs, Reusable Module: /modules/glue_job
############################################### 
## Glue Job, Reporting Hub
## Glue Cloud Platform Ingestion Job (Load, Reload, CDC)
locals {
  glue_avro_registry           = split("/", module.glue_registry_avro.registry_name)
  shared_log4j_properties_path = "s3://${aws_s3_object.glue_job_shared_custom_log4j_properties.bucket}/${aws_s3_object.glue_job_shared_custom_log4j_properties.key}"
  glue_datahub_job_extra_operational_datastore_args = (local.create_glue_connection && local.enable_operational_datastore_job_access ? {
    "--dpr.operational.data.store.write.enabled"              = "true"
    "--dpr.operational.data.store.glue.connection.name"       = aws_glue_connection.glue_operational_datastore_connection[0].name
    "--dpr.operational.data.store.loading.schema.name"        = "loading"
    "--dpr.operational.data.store.tables.to.write.table.name" = "configuration.datahub_managed_tables"
    "--dpr.operational.data.store.jdbc.batch.size"            = 5000
  } : {})
}

resource "aws_s3_object" "glue_job_shared_custom_log4j_properties" {
  bucket = module.s3_glue_job_bucket.bucket_id
  key    = "logging/misc-jobs/log4j2.properties"
  source = "files/log4j2.properties"
  etag   = filemd5("files/log4j2.properties")
}

# Glue Job, Create Hive Tables
module "glue_hive_table_creation_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-hive-table-creation-${local.env}"
  short_name                    = "${local.project}-hive-table-creation"
  command_type                  = "glueetl"
  glue_version                  = local.glue_job_version
  description                   = "Creates Hive tables for schemas in the registry.\nArguments:\n--dpr.config.key: (Optional) config key e.g. prisoner"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-hive-table-creation-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-hive-table-creation-${local.env}/"
  # Placeholder Script Location
  script_location              = local.glue_placeholder_script_location
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn

  execution_class             = "STANDARD"
  worker_type                 = "G.1X"
  number_of_workers           = 2
  max_concurrent              = 64
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = local.glue_log_retention_in_days

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-hive-table-creation-${local.env}"
      dpr-resource-type = "Glue Job"
      dpr-jira          = "DPR2-209"
    }
  )

  arguments = {
    "--extra-jars"                = local.glue_jobs_latest_jar_location
    "--extra-files"               = local.shared_log4j_properties_path
    "--class"                     = "uk.gov.justice.digital.job.HiveTableCreationJob"
    "--dpr.aws.region"            = local.account_region
    "--dpr.config.s3.bucket"      = module.s3_glue_job_bucket.bucket_id,
    "--dpr.raw.archive.s3.path"   = "s3://${module.s3_raw_archive_bucket.bucket_id}"
    "--dpr.structured.s3.path"    = "s3://${module.s3_structured_bucket.bucket_id}"
    "--dpr.curated.s3.path"       = "s3://${module.s3_curated_bucket.bucket_id}"
    "--dpr.raw_archive.database"  = module.glue_raw_archive_database.db_name
    "--dpr.structured.database"   = module.glue_structured_zone_database.db_name
    "--dpr.curated.database"      = module.glue_curated_zone_database.db_name
    "--dpr.prisons.database"      = module.glue_prisons_database.db_name
    "--dpr.contract.registryName" = module.s3_schema_registry_bucket.bucket_id
    "--dpr.schema.cache.max.size" = local.hive_table_creation_job_schema_cache_max_size
    "--dpr.log.level"             = local.glue_job_common_log_level
  }

  depends_on = [
    module.s3_raw_archive_bucket.bucket_id,
    module.s3_structured_bucket.bucket_id,
    module.s3_curated_bucket.bucket_id,
    module.s3_glue_job_bucket.bucket_id,
    module.glue_raw_archive_database.db_name,
    module.glue_structured_zone_database.db_name,
    module.glue_curated_zone_database.db_name,
    module.glue_prisons_database.db_name,
    module.glue_registry_avro.registry_name
  ]
}

# Glue Job, S3 File Archive Job
module "glue_s3_file_transfer_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-s3-file-transfer-job-${local.env}"
  short_name                    = "${local.project}-s3-file-transfer-job"
  command_type                  = "glueetl"
  glue_version                  = local.glue_job_version
  description                   = "Transfers s3 data from one bucket to another.\nArguments:\n--dpr.config.key: (Optional) config key e.g prisoner, when provided, the job will only transfer data belonging to specified config otherwise all data will be transferred"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-s3-file-transfer-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-s3-file-transfer-${local.env}/"
  # Placeholder Script Location
  script_location              = local.glue_placeholder_script_location
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn

  execution_class             = "STANDARD"
  worker_type                 = "G.1X"
  number_of_workers           = 2
  max_concurrent              = 64
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = local.glue_log_retention_in_days

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-s3-file-transfer-${local.env}"
      dpr-resource-type = "Glue Job"
      dpr-jira          = "DPR2-46"
    }
  )

  arguments = {
    "--extra-jars"                                = local.glue_jobs_latest_jar_location
    "--extra-files"                               = local.shared_log4j_properties_path
    "--class"                                     = "uk.gov.justice.digital.job.S3FileTransferJob"
    "--dpr.aws.region"                            = local.account_region
    "--dpr.config.s3.bucket"                      = module.s3_glue_job_bucket.bucket_id,
    "--dpr.file.transfer.source.bucket"           = module.s3_raw_bucket.bucket_id
    "--dpr.file.transfer.destination.bucket"      = module.s3_raw_archive_bucket.bucket_id
    "--dpr.file.transfer.retention.period.amount" = tostring(local.scheduled_s3_file_transfer_retention_period_amount)
    "--dpr.file.transfer.retention.period.unit"   = tostring(local.scheduled_s3_file_transfer_retention_period_unit)
    "--dpr.file.transfer.use.default.parallelism" = tostring(local.scheduled_file_transfer_use_default_parallelism)
    "--dpr.file.transfer.parallelism"             = tostring(local.scheduled_file_transfer_parallelism)
    "--dpr.file.transfer.delete.copied.files"     = true,
    "--dpr.allowed.s3.file.extensions"            = "*",
    "--dpr.log.level"                             = local.glue_job_common_log_level
  }

  depends_on = [
    module.s3_raw_bucket.bucket_id,
    module.s3_raw_archive_bucket.bucket_id,
    module.s3_glue_job_bucket
  ]
}

# Glue Job, Switch Prisons Hive Data Location
module "glue_switch_prisons_hive_data_location_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-switch-prisons-data-source-${local.env}"
  short_name                    = "${local.project}-switch-prisons-data-source"
  command_type                  = "glueetl"
  glue_version                  = local.glue_job_version
  description                   = "Switch Prisons Hive tables data location.\nArguments:\n--dpr.config.key: (Required) config key e.g. prisoner\n--dpr.prisons.data.switch.target.s3.path: (Required) s3 path to point the prisons data to e.g. s3://dpr-curated-zone-<env>"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-switch-prisons-data-source-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-switch-prisons-data-source-${local.env}/"
  # Placeholder Script Location
  script_location              = local.glue_placeholder_script_location
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn

  execution_class             = "STANDARD"
  worker_type                 = "G.1X"
  number_of_workers           = 2
  max_concurrent              = 64
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = local.glue_log_retention_in_days

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-switch-prisons-data-source-${local.env}"
      dpr-resource-type = "Glue Job"
      dpr-jira          = "DPR2-46"
    }
  )

  arguments = {
    "--extra-jars"                = local.glue_jobs_latest_jar_location
    "--extra-files"               = local.shared_log4j_properties_path
    "--class"                     = "uk.gov.justice.digital.job.SwitchHiveTableJob"
    "--dpr.aws.region"            = local.account_region
    "--dpr.config.s3.bucket"      = module.s3_glue_job_bucket.bucket_id,
    "--dpr.prisons.database"      = module.glue_prisons_database.db_name
    "--dpr.contract.registryName" = module.s3_schema_registry_bucket.bucket_id
    "--dpr.schema.cache.max.size" = local.hive_table_creation_job_schema_cache_max_size
    "--dpr.log.level"             = local.glue_job_common_log_level
  }

  depends_on = [
    module.s3_raw_archive_bucket.bucket_id,
    module.s3_structured_bucket.bucket_id,
    module.s3_curated_bucket.bucket_id,
    module.s3_glue_job_bucket.bucket_id,
    module.glue_raw_archive_database.db_name,
    module.glue_structured_zone_database.db_name,
    module.glue_curated_zone_database.db_name,
    module.glue_prisons_database.db_name,
    module.glue_registry_avro.registry_name
  ]
}

# Glue Job, S3 Data Deletion Job
module "glue_s3_data_deletion_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-s3-data-deletion-job-${local.env}"
  short_name                    = "${local.project}-s3-data-deletion-job"
  command_type                  = "glueetl"
  glue_version                  = local.glue_job_version
  description                   = "Deletes s3 data belonging to a configured domain from specified bucket.\nArguments:\n--dpr.config.key: (Required) config key e.g. prisoner\n--dpr.file.deletion.buckets: (Required) comma separated set of s3 buckets from which to delete data from e.g dpr-raw-zone-<env>,dpr-structured-zone-<env>"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-s3-data-deletion-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-s3-data-deletion-${local.env}/"
  # Placeholder Script Location
  script_location              = local.glue_placeholder_script_location
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn

  execution_class             = "STANDARD"
  worker_type                 = "G.1X"
  number_of_workers           = 2
  max_concurrent              = 64
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = local.glue_log_retention_in_days

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-s3-data-deletion-${local.env}"
      dpr-resource-type = "Glue Job"
      dpr-jira          = "DPR2-46"
    }
  )

  arguments = {
    "--extra-jars"                     = local.glue_jobs_latest_jar_location
    "--extra-files"                    = local.shared_log4j_properties_path
    "--class"                          = "uk.gov.justice.digital.job.S3DataDeletionJob"
    "--dpr.aws.region"                 = local.account_region
    "--dpr.config.s3.bucket"           = module.s3_glue_job_bucket.bucket_id,
    "--dpr.allowed.s3.file.extensions" = "*"
    "--dpr.log.level"                  = local.glue_job_common_log_level
  }

  depends_on = [
    module.s3_raw_bucket.bucket_id,
    module.s3_raw_archive_bucket.bucket_id,
    module.s3_structured_bucket.bucket_id,
    module.s3_curated_bucket.bucket_id,
    module.s3_temp_reload_bucket.bucket_id
  ]
}

# Glue Job, Stop Glue Instance Job
module "glue_stop_glue_instance_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-stop-glue-instance-job-${local.env}"
  short_name                    = "${local.project}-stop-glue-instance-job"
  command_type                  = "glueetl"
  glue_version                  = local.glue_job_version
  description                   = "Stops a running Glue job instance.\nArguments:\n--dpr.stop.glue.instance.job.name: (Required) name of the glue job whose running instance is to be stopped"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-stop-glue-instance-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-stop-glue-instance-${local.env}/"
  # Placeholder Script Location
  script_location              = local.glue_placeholder_script_location
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn

  execution_class             = "STANDARD"
  worker_type                 = "G.1X"
  number_of_workers           = 2
  max_concurrent              = 64
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = local.glue_log_retention_in_days

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-stop-glue-instance-${local.env}"
      dpr-resource-type = "Glue Job"
      dpr-jira          = "DPR2-46"
    }
  )

  arguments = {
    "--extra-jars"     = local.glue_jobs_latest_jar_location
    "--extra-files"    = local.shared_log4j_properties_path
    "--class"          = "uk.gov.justice.digital.job.StopGlueInstanceJob"
    "--dpr.aws.region" = local.account_region
    "--dpr.log.level"  = local.glue_job_common_log_level
  }
}

# Glue Job, Stop DMS Task Job
module "stop_dms_task_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-stop-dms-task-job-${local.env}"
  short_name                    = "${local.project}-stop-dms-task-job"
  command_type                  = "glueetl"
  glue_version                  = local.glue_job_version
  description                   = "Stops a running DMS replication task.\nArguments:\n--dpr.dms.replication.task.id: (Required) ID of the DMS replication task which is to be stopped"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-stop-dms-task-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-stop-dms-task-${local.env}/"
  # Placeholder Script Location
  script_location              = local.glue_placeholder_script_location
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn

  execution_class             = "STANDARD"
  worker_type                 = "G.1X"
  number_of_workers           = 2
  max_concurrent              = 64
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = local.glue_log_retention_in_days

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-stop-dms-task-${local.env}"
      dpr-resource-type = "Glue Job"
      dpr-jira          = "DPR2-713"
    }
  )

  arguments = {
    "--extra-jars"     = local.glue_jobs_latest_jar_location
    "--extra-files"    = local.shared_log4j_properties_path
    "--class"          = "uk.gov.justice.digital.job.StopDmsTaskJob"
    "--dpr.aws.region" = local.account_region
    "--dpr.log.level"  = local.glue_job_common_log_level
  }
}

# Glue Job, Set the CDC DMS Start Time
module "set_cdc_dms_start_time_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-set-cdc-dms-start-time-job-${local.env}"
  short_name                    = "${local.project}-set-cdc-dms-start-time-job"
  command_type                  = "glueetl"
  glue_version                  = local.glue_job_version
  description                   = "Sets the start time of a CDC DMS Task associated with a given Full-Load task.\nArguments:\n--dpr.dms.replication.task.id: (Required) Id of the Full-Load DMS task from which the start time of the CDC task will be obtained\n--dpr.cdc.dms.replication.task.id: (Required) Id of the CDC DMS task for which the start time is to be updated"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-set-cdc-dms-start-time-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-set-cdc-dms-start-time-${local.env}/"
  # Placeholder Script Location
  script_location              = local.glue_placeholder_script_location
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn

  execution_class             = "STANDARD"
  worker_type                 = "G.1X"
  number_of_workers           = 2
  max_concurrent              = 64
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = local.glue_log_retention_in_days

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-set-cdc-dms-start-time-${local.env}"
      dpr-resource-type = "Glue Job"
      dpr-jira          = "DPR2-1925"
    }
  )

  arguments = {
    "--extra-jars"    = local.glue_jobs_latest_jar_location
    "--extra-files"   = local.shared_log4j_properties_path
    "--class"         = "uk.gov.justice.digital.job.UpdateDmsCdcTaskStartTimeJob"
    "--dpr.log.level" = local.glue_job_common_log_level
  }
}

# Glue Job, Activate/Deactivate Glue Trigger Job
module "activate_glue_trigger_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-activate-glue-trigger-job-${local.env}"
  short_name                    = "${local.project}-activate-glue-trigger-job"
  command_type                  = "glueetl"
  glue_version                  = local.glue_job_version
  description                   = "Activates/Deactivates a Glue trigger.\nArguments:\n--dpr.glue.trigger.name: (Required) Name of the Glue trigger to be activated/deactivated\n--dpr.glue.trigger.activate: (Required) when true, activates the trigger"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-activate-glue-trigger-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-activate-glue-trigger-${local.env}/"
  # Placeholder Script Location
  script_location              = local.glue_placeholder_script_location
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn

  execution_class             = "STANDARD"
  worker_type                 = "G.1X"
  number_of_workers           = 2
  max_concurrent              = 64
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = local.glue_log_retention_in_days

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-activate-glue-trigger-${local.env}"
      dpr-resource-type = "Glue Job"
      dpr-jira          = "DPR2-713"
    }
  )

  arguments = {
    "--extra-jars"     = local.glue_jobs_latest_jar_location
    "--extra-files"    = local.shared_log4j_properties_path
    "--class"          = "uk.gov.justice.digital.job.GlueTriggerActivationJob"
    "--dpr.aws.region" = local.account_region
    "--dpr.log.level"  = local.glue_job_common_log_level
  }
}

# Glue Registry
module "glue_registry_avro" {
  source               = "./modules/glue_registry"
  enable_glue_registry = true
  name                 = "${local.project}-glue-registry-avro-${local.env}"
  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-glue-registry-avro-${local.env}"
      dpr-resource-type = "Glue Registry"
      dpr-jira          = "DPR-108"
    }
  )
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
      dpr-name          = "${local.project}-glue-jobs-${local.environment}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR-108"
    }
  )
}

# S3 Raw Archive
module "s3_raw_archive_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-raw-archive-${local.env}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-raw-archive-${local.env}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR2-209"
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
      dpr-name          = "${local.project}-raw-zone-${local.env}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR-108"
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
      dpr-name          = "${local.project}-structured-zone-${local.env}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR-108"
    }
  )
}

# S3 Curated
module "s3_curated_bucket" {
  source                     = "./modules/s3_bucket"
  create_s3                  = local.setup_buckets
  name                       = "${local.project}-curated-zone-${local.env}"
  custom_kms_key             = local.s3_kms_arn
  create_notification_queue  = false # For SQS Queue
  enable_lifecycle           = true
  enable_intelligent_tiering = false

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-curated-zone-${local.env}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR-108"
    }
  )
}

# S3 Temp Reload
module "s3_temp_reload_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-temp-reload-${local.env}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-temp-reload-${local.env}"
      dpr-resource-type = "S3 Bucket",
      dpr-jira          = "DPR2-46"
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
      dpr-name          = "${local.project}-domain-${local.env}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR-108"
    }
  )
}

# Schema Registry Bucket
module "s3_schema_registry_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-schema-registry-${local.env}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true
  enable_s3_versioning      = true
  enable_versioning_config  = "Enabled"

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-schema-registry-${local.env}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR2-245"
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
      dpr-name          = "${local.project}-domain-config-${local.env}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR-108"
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
      dpr-name          = "${local.project}-violation-${local.environment}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR-108"
    }
  )
}

# S3 Landing Zone Bucket. Used by File Transfer In/Push
module "s3_landing_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-landing-zone-${local.environment}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-landing-zone-${local.environment}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR2-1499"
    }
  )
}

# S3 Landing Processing Zone Bucket. Used by File Transfer In/Push
module "s3_landing_processing_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-landing-processing-zone-${local.environment}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-landing-processing-zone-${local.environment}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR2-1499"
    }
  )
}

# S3 Quarantine Zone Bucket. Used by File Transfer In/Push
module "s3_quarantine_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-quarantine-zone-${local.environment}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-quarantine-zone-${local.environment}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR2-1499"
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
    "lambda_function_arn" = module.domain_builder_flyway_Lambda.lambda_function
    "events"              = ["s3:ObjectCreated:*"]
    "filter_prefix"       = "build-artifacts/domain-builder/jars/"
    "filter_suffix"       = ".jar"
  }

  dependency_lambda = [module.domain_builder_flyway_Lambda.lambda_function] # Required if bucket_notications is enabled

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-artifact-store-${local.environment}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR-108"
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
  lifecycle_category        = "long_term"

  override_expiration_rules = [
    {
      id     = "reports"
      prefix = "reports/"
      days   = local.s3_redshift_table_expiry_days
    },
    {
      id     = "dpr"
      prefix = "dpr/"
      days   = 7
    }
  ]

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-working-${local.environment}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR-108"
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

# Glue Database Catalog for Raw Archive
module "glue_raw_archive_database" {
  source         = "./modules/glue_database"
  create_db      = local.create_db
  name           = "raw_archive"
  description    = "Glue Data Catalog - Raw Archive"
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

# Glue Database Catalog for Prisons Fabric
module "glue_prisons_database" {
  source         = "./modules/glue_database"
  create_db      = local.create_db
  name           = "prisons"
  description    = "Glue Data Catalog - Prisons Fabric"
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

# Ec2
module "ec2_bastion_host" {
  source                      = "./modules/ec2"
  name                        = "${local.project}-ec2-bastion-host-${local.env}"
  description                 = "EC2 bastion instance for accessing the private network"
  vpc                         = data.aws_vpc.shared.id
  cidr                        = [data.aws_vpc.shared.cidr_block]
  subnet_ids                  = data.aws_subnet.private_subnets_a.id
  ec2_instance_type           = local.instance_type
  ami_image_id                = local.image_id
  aws_region                  = local.account_region
  ec2_terminate_behavior      = "terminate"
  associate_public_ip_address = false
  static_private_ip           = "10.26.24.201" # Used for Dev as a Secondary IP
  ebs_optimized               = true
  monitoring                  = true
  ebs_size                    = 20
  ebs_encrypted               = true
  scale_down                  = local.bastion_host_autoscale
  ebs_delete_on_termination   = false
  # s3_policy_arn               = aws_iam_policy.read_s3_read_access_policy.arn # TBC
  region  = local.account_region
  account = local.account_id
  env     = local.env

  ec2_sec_rules_source_sec_group = {
    "NOMIS_FROM_GLUE" = {
      "from_port"                = local.nomis_port,
      "to_port"                  = local.nomis_port,
      "protocol"                 = "TCP",
      "source_security_group_id" = aws_security_group.glue_job_connection_sg.id
    }
  }


  tags = merge(
    local.all_tags,
    {
      Name              = "${local.project}-ec2-bastion-host-${local.env}"
      dpr-name          = "${local.project}-ec2-bastion-host-${local.env}"
      dpr-resource-type = "EC2 Instance"
      dpr-jira          = "DPR-108"
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
  subnet_ids = [
    data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id
  ]
  vpc           = data.aws_vpc.shared.id
  cidr          = [data.aws_vpc.shared.cidr_block, local.cloud_platform_cidr]
  iam_role_arns = [aws_iam_role.redshift-role.arn, aws_iam_role.redshift-spectrum-role.arn]

  # Endpoint access - only available when using the ra3.x type, for S3 Simple Service
  create_endpoint_access = false

  # Parameter Group Parameters, including Work Load Management
  parameter_group_parameters = {
    wlm_json_configuration = {
      name  = "wlm_json_configuration"
      value = jsonencode(jsondecode(file("./datamart-redshift-wlm.json")))
    },
    enable_user_activity_logging = {
      name  = "enable_user_activity_logging"
      value = "true"
    }
  }

  # Scheduled actions
  create_scheduled_action_iam_role = local.create_scheduled_action_iam_role
  create_redshift_schedule         = local.create_redshift_schedule
  scheduled_actions = {
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
    retention_period     = local.other_log_retention_in_days
    log_exports          = ["useractivitylog", "userlog", "connectionlog"]
  }

  tags = merge(
    local.all_tags,
    {
      dpr-name          = local.redshift_cluster_name
      dpr-resource-type = "Redshift Cluster"
      dpr-jira          = "DPR-108"
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
      dpr-name          = "${local.project}-domain-registry-${local.environment}"
      dpr-resource-type = "Dynamo Table"
      dpr-jira          = "DPR-306"
    }
  )
}

# Dynamo table for StepFunctions DMS Tokens, DPR2-209
module "dynamo_table_step_functions_token" {
  source              = "./modules/dynamo_tables"
  create_table        = true
  autoscaling_enabled = false
  name                = "${local.project}-step-function-tokens"

  hash_key    = "replicationTaskArn"
  table_class = "STANDARD"

  ttl_enabled        = true
  ttl_attribute_name = "expireAt"

  attributes = [
    {
      name = "replicationTaskArn"
      type = "S"
    },
    {
      name = "expireAt"
      type = "N"
    }
  ]

  global_secondary_indexes = [
    {
      name            = "expireAt-index"
      hash_key        = "expireAt"
      write_capacity  = 2
      read_capacity   = 2
      projection_type = "ALL"
    }
  ]

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-step-functions-${local.environment}"
      dpr-resource-type = "Dynamo Table"
      dpr-jira          = "DPR2-209"
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
      dpr-name          = "${local.project}-terraform-state-${local.environment}"
      dpr-resource-type = "S3 Bucket"
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
      dpr-name          = "${local.project}-terraform-state-${local.environment}"
      dpr-resource-type = "Dynamo Table"
    }
  )
}

# Glue Job, Temporary Job to Generate Test Data to the DPR Read-Replica Testing Postgres
module "generate_test_postgres_data" {
  count = local.create_postgres_load_generator_job ? 1 : 0

  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-load-generator-job-${local.env}"
  short_name                    = "${local.project}-load-generator-job"
  command_type                  = "glueetl"
  glue_version                  = local.glue_job_version
  description                   = "Inserts a given number of records to postgres database.\nArguments:\n--dpr.test.database.secret.id: (Required) The Id of the secret to connect to the Postgres database\n--dpr.test.data.batch.size: (Optional) Total number of records to insert per batch\n--dpr.test.data.parallelism: (Optional) Total number of parallel batches\n--dpr.test.data.inter.batch.delay.millis: (Optional) Amount of milliseconds to wait between batches\n--dpr.test.data.run.duration.millis: (Optional) Total run duration of data generation in milliseconds"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-load-generator-job-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-load-generator-job-${local.env}/"
  # Placeholder Script Location
  script_location              = local.glue_placeholder_script_location
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn
  connections                  = ["${local.project}-dps-test-db-connection"]

  execution_class             = "STANDARD"
  worker_type                 = "G.1X"
  number_of_workers           = 2
  max_concurrent              = 1
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = local.glue_log_retention_in_days

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-load-generator-job-${local.env}"
      dpr-resource-type = "Glue Job"
      dpr-jira          = "DPR2-1884"
    }
  )

  arguments = {
    "--extra-jars"                             = local.glue_jobs_latest_jar_location
    "--extra-files"                            = local.shared_log4j_properties_path
    "--class"                                  = "uk.gov.justice.digital.job.generator.PostgresLoadGeneratorJob"
    "--dpr.aws.region"                         = local.account_region
    "--dpr.log.level"                          = local.glue_job_common_log_level
    "--dpr.test.database.secret.id"            = "external/dpr-dps-test-db-source-secrets"
    "--dpr.test.data.batch.size"               = 5
    "--dpr.test.data.parallelism"              = 100
    "--dpr.test.data.inter.batch.delay.millis" = 2000
  }
}

# Glue Trigger, Temporary Glue Trigger for the Postgres Test Data Generation Job
resource "aws_glue_trigger" "glue_postgres_data_generator_job_trigger" {
  count = local.create_postgres_load_generator_job ? 1 : 0

  name     = "${module.generate_test_postgres_data[0].name}-trigger"
  schedule = "cron(0 0/2 ? * * *)" # runs every 2 hours
  type     = "SCHEDULED"
  enabled  = false

  actions {
    job_name = module.generate_test_postgres_data[0].name
  }

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-load-generator-trigger-${local.env}"
      dpr-resource-type = "Glue Trigger"
      dpr-jira          = "DPR2-1884"
    }
  )
}
