############################
# Federated Cloud Platform # 
############################
# Glue Cloud Platform Ingestion Job (Load, Reload, CDC)
module "glue_reporting_hub_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-reporting-hub-${local.env}"
  description                   = local.description
  command_type                  = "gluestreaming"
  create_security_configuration = local.create_sec_conf
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/reporting-hub/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/reporting-hub/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/reporting-hub/"
  tags                          = local.all_tags
  enable_continuous_log_filter  = false
  project_id                    = local.project
  aws_kms_key                   = local.s3_kms_arn
  create_kinesis_ingester       = local.create_kinesis # If True, Kinesis Policies are applied
  additional_policies           = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
  timeout                       = 8
  execution_class               = "STANDARD"
  # Placeholder Script Location
  script_location = "s3://${local.project}-artifact-store-${local.environment}/artifacts/domain-platform/digital-prison-reporting-poc/place-holder-vLatest.scala"

  class = "uk.gov.justice.digital.job.DataHubJob"

  arguments = {
    "--extra-jars"                          = "s3://${local.project}-artifact-store-${local.environment}/artifacts/cloud-platform/digital-prison-reporting-poc/cloud-platform-vLatest.jar"
    "--job-bookmark-option"                 = "job-bookmark-disable"
    "--enable-metrics"                      = true
    "--enable-spark-ui"                     = false
    "--enable-job-insights"                 = true
    "--kinesis.reader.streamName"           = local.kinesis_stream_ingestor
    "--aws.kinesis.endpointUrl"             = "https://kinesis-${local.account_region}.amazonaws.com"
    "--aws.region"                          = local.account_region
    "--kinesis.reader.batchDurationSeconds" = 1
    "--datalake-formats"                    = "delta"
    "--raw.s3.path"                         = "s3://${module.s3_raw_bucket.bucket_id}"
    "--structured.s3.path"                  = "s3://${module.s3_structured_bucket.bucket_id}"
  }
}

# REMOVE - (DPR-378)
# Glue Kinesis Reader Job (DPR-340)
#module "glue_kinesis_reader_job" {
#  source                        = "./modules/glue_job"
#  create_job                    = local.create_job
#  name                          = "${local.project}-kinesis-reader-${local.env}"
#  description                   = "kinesis Reader Job"
#  job_language                  = "scala"
#  command_type                  = "gluestreaming"
#  create_security_configuration = local.create_sec_conf
#  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/reporting-hub/"
#  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/reporting-hub/"
#  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/reporting-hub/"
#  enable_continuous_log_filter  = false
#  project_id                    = local.project
#  aws_kms_key                   = local.s3_kms_arn
#  create_kinesis_ingester       = local.create_kinesis # If True, Kinesis Policies are applied - Defaults to True
#  additional_policies           = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
#  timeout                       = 2880 # This is in Mins
#  execution_class               = "STANDARD"
#  # Placeholder Script Location
#  script_location = "s3://${local.project}-artifact-store-${local.environment}/artifacts/cloud-platform/digital-prison-reporting-jobs/scripts/${local.project}-kinesis-reader-vLatest.scala"

#  class = "uk.gov.justice.digital.job.DataHubJob"

#  tags = merge(
#    local.all_tags,
#    {
#      Name          = "${local.project}-kinesis-reader-${local.env}"
#      Resource_Type = "Glue Job"
#      Ticket        = "DPR-340"
#    }
#  )

#  arguments = {
#    "--extra-jars"                          = "s3://${local.project}-artifact-store-${local.environment}/artifacts/cloud-platform/digital-prison-reporting-jobs/jars/digital-prison-reporting-jobs-vLatest.jar"
#    "--job-bookmark-option"                 = "job-bookmark-disable"
#    "--enable-metrics"                      = true
#    "--enable-spark-ui"                     = false
#    "--enable-job-insights"                 = true
#    "--kinesis.reader.streamName"           = "${local.project}-kinesis-reader-${local.env}-stream"
#    "--aws.kinesis.endpointUrl"             = "https://kinesis-${local.account_region}.amazonaws.com"
#    "--aws.region"                          = local.account_region
#    "--kinesis.reader.batchDurationSeconds" = 1
#    "--class"                               = "uk.gov.justice.digital.job.DataHubJob"
#  }
#}

# REMOVE - (DPR-378)
# Glue Domain Platform Change Monitor Job
#module "glue_domainplatform_change_monitor_job" {
#  source                        = "./modules/glue_job"
#  create_job                    = local.create_job
#  name                          = "${local.project}-domain-platform-table-change-monitor-${local.env}"
#  description                   = "Monitors the reporting hub for table changes and applies them to domains"
#  create_security_configuration = local.create_sec_conf
#  job_language                  = "scala"
#  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/change-monitor/"
#  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/change-monitor/"
#  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/change-monitor/"
#  tags                          = local.all_tags
#  script_location               = "s3://${local.project}-artifact-store-${local.environment}/artifacts/domain-platform/digital-prison-reporting-poc/domain-platform-table-change-monitor-vLatest.scala"
#  enable_continuous_log_filter  = false
#  project_id                    = local.project
#  aws_kms_key                   = local.s3_kms_arn
#  create_kinesis_ingester       = local.create_kinesis # If True, Kinesis Policies are applied
#  additional_policies           = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_read_only_arn
#  timeout                       = 120
#  execution_class               = "FLEX"
#  arguments = {
#    "--extra-jars"          = "s3://${local.project}-artifact-store-${local.environment}/artifacts/domain-platform/digital-prison-reporting-poc/domain-platform-vLatest.jar"
#    "--class"               = "GlueApp"
#    "--cloud.platform.path" = "s3://${module.s3_curated_bucket.bucket_id}"
#    "--domain.files.path"   = "s3://${module.s3_domain_config_bucket.bucket_id}/"
#    "--domain.repo.path"    = "s3://${module.s3_glue_job_bucket.bucket_id}/domain-repo/" ## Added /
#    "--source.queue"        = "domain-cdc-event-notification"                            ## DPR-287, needs right source - TBC
#    "--source.region"       = local.account_region
#    "--target.path"         = "s3://${module.s3_domain_bucket.bucket_id}/"               ## Added /
#    "--checkpoint.location" = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/change-monitor/"
#  }
#}

# Glue Domain Platform Refresh Job
module "glue_domain_refresh_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-domain-refresh-${local.env}"
  command_type                  = "glueetl"
  description                   = "Monitors the reporting hub for table changes and applies them to domains"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-domain-refresh-${local.env}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.project}-domain-refresh-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-domain-refresh-${local.env}/"
  script_location               = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/scripts/digital-prison-reporting-jobs-vLatest.scala"
  enable_continuous_log_filter  = false
  project_id                    = local.project
  aws_kms_key                   = local.s3_kms_arn
  create_kinesis_ingester       = local.create_kinesis # If True, Kinesis Policies are applied
  additional_policies           = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
  timeout                       = 120
  execution_class               = "FLEX"
  worker_type                   = "G.1X"
  number_of_workers             = 2
  max_concurrent                = 1

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-domain-refresh-${local.env}"
      Resource_Type = "Glue Job"
      Jira          = "DPR-265"
    }
  )

  arguments = {
    "--extra-jars"                    = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/digital-prison-reporting-jobs-vLatest-all.jar"
    "--class"                         = "uk.gov.justice.digital.job.DomainRefreshJob"
    "--datalake-formats"              = "delta"
    "--dpr.aws.dynamodb.endpointUrl"  = "https://dynamodb.eu-west-2.amazonaws.com"
    "--dpr.aws.region"                = "eu-west-2"
    "--dpr.curated.s3.path"           = "s3://${module.s3_curated_bucket.bucket_id}/curated/"
    "--dpr.domain.name"               = "establishment"
    "--dpr.domain.operation"          = "UPDATE"
    "--dpr.domain.registry"           = "DomainRegistry"
    "--dpr.domain.table.name"         = "establishment"
    "--dpr.domain.target.path"        =  "s3://${module.s3_domain_bucket.bucket_id}/domains/"
  }
}

# kinesis Data Stream Ingestor
module "kinesis_stream_ingestor" {
  source                    = "./modules/kinesis_stream"
  create_kinesis_stream     = local.create_kinesis
  name                      = local.kinesis_stream_ingestor
  shard_count               = 1 # Not Valid when ON-DEMAND Mode
  retention_period          = 24
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

# REMOVE - (DPR-378)
# kinesis Domain Data Stream
#module "kinesis_stream_domain_data" {
#  source                    = "./modules/kinesis_stream"
#  create_kinesis_stream     = local.create_kinesis
#  name                      = local.kinesis_stream_data_domain
#  shard_count               = 1 # Not Valid when ON-DEMAND Mode
#  retention_period          = 24
#  shard_level_metrics       = ["IncomingBytes", "OutgoingBytes"]
#  enforce_consumer_deletion = false
#  encryption_type           = "KMS"
#  kms_key_id                = local.kinesis_kms_id
#  project_id                = local.project

#  tags = merge(
#   local.all_tags,
#    {
#      Name          = "${local.project}-kinesis-domain-data-${local.env}"
#      Resource_Type = "Kinesis Data Stream"
#      Component     = "Domain Data"
#    }
#  )
#}

# REMOVE - (DPR-378)
# kinesis DEMO Data Stream
#module "kinesis_stream_demo_data" {
#  source                    = "./modules/kinesis_stream"
#  create_kinesis_stream     = local.create_kinesis
#  name                      = "${local.project}-kinesis-data-demo-${local.env}"
#  shard_count               = 1 # Not Valid when ON-DEMAND Mode
#  retention_period          = 24
#  shard_level_metrics       = ["IncomingBytes", "OutgoingBytes"]
#  enforce_consumer_deletion = false
#  encryption_type           = "KMS"
#  kms_key_id                = local.kinesis_kms_id
#  project_id                = local.project

#  tags = merge(
#    local.all_tags,
#    {
#      Name          = "${local.project}-kinesis-data-demo-${local.env}"
#      Resource_Type = "Kinesis Data Stream"
#      Component     = "Demo"
#    }
#  )
#}

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

## Glue Database Raw Glue Catalog 
##module "glue_raw_database" {
##  source         = "./modules/glue_database"
##  create_db      = local.create_db
##  name           = "${local.project}-raw-${local.env}"
##  description    = "Glue Database Raw Catalog"
##  aws_account_id = local.account_id
##  aws_region     = local.account_region
##}

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
  password          = ""   ## Needs to pull from Secrets Manager, #TD
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
  master_password         = "Datamartpass2022" ## Needs to pull from Secrets Manager, #TD
  create_random_password  = false
  encrypted               = true
  create_subnet_group     = true
  kms_key_arn             = aws_kms_key.redshift-kms-key.arn
  enhanced_vpc_routing    = false
  subnet_ids              = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  vpc                     = data.aws_vpc.shared.id
  cidr                    = [data.aws_vpc.shared.cidr_block]
  iam_role_arns           = aws_iam_role.redshift-role.*.arn

  # Endpoint access - only available when using the ra3.x type, for S3 Simple Service
  create_endpoint_access = false

  # Scheduled actions
  create_scheduled_action_iam_role = true
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

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.redshift_cluster_name}"
      Resource_Type = "Redshift Cluster"
    }
  )
}

###############################
# Application Artifacts Store # 
###############################
# S3 Bucket (Application Artifacts Store)
module "s3_artifacts_store" {
  source         = "./modules/s3_bucket"
  create_s3      = local.setup_buckets
  name           = "${local.project}-artifact-store-${local.environment}"
  custom_kms_key = local.s3_kms_arn

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-artifact-store-${local.environment}"
      Resource_Type = "S3 Bucket"
    }
  )
}

# DMS Nomis Data Collector
module "dms_nomis_ingestor" {
  source                = "./modules/dms"
  name                  = "${local.project}-dms-nomis-ingestor-${local.env}"
  vpc_cidr              = [data.aws_vpc.shared.cidr_block]
  source_engine_name    = "oracle"
  source_db_name        = "CNOMT3"
  source_app_username   = "digital_prison_reporting"
  source_app_password   = "DSkpo4n7GhnmIV" ## Needs to pull from Secrets Manager, #TD
  source_address        = "10.101.63.135"
  source_db_port        = 1521
  vpc                   = data.aws_vpc.shared.id
  kinesis_stream_policy = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
  project_id            = local.project
  env                   = local.environment
  dms_source_name       = "oracle"
  dms_target_name       = "kinesis"
  short_name            = "nomis"
  migration_type        = "full-load-and-cdc"
  subnet_ids            = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]

  vpc_role_dependency        = [aws_iam_role.dmsvpcrole]
  cloudwatch_role_dependency = [aws_iam_role.dms_cloudwatch_logs_role]

  kinesis_settings = {
    "include_null_and_empty"          = "true"
    "partition_include_schema_table"  = "true"
    "include_partition_value"         = "true"
    "kinesis_target_stream"           = "arn:aws:kinesis:eu-west-2:${data.aws_caller_identity.current.account_id}:stream/${local.kinesis_stream_ingestor}"
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

## REMOVE (DPR-378)
# DMS Useforce Data Collector
#module "dms_use_of_force" {
#  source                = "./modules/dms"
#  name                  = "${local.project}-dms-use-force-ingestor-${local.env}"
#  vpc_cidr              = [data.aws_vpc.shared.cidr_block]
#  source_engine_name    = "postgres"
#  source_db_name        = "use_of_force"
#  source_app_username   = "postgres"
#  source_app_password   = ""
#  source_address        = "dpr-development-use-of-force-rds.cja8lnnvvipo.eu-west-2.rds.amazonaws.com"
#  source_db_port        = 5432
#  vpc                   = data.aws_vpc.shared.id
#  kinesis_target_stream = "arn:aws:kinesis:eu-west-2:${data.aws_caller_identity.current.account_id}:stream/dpr-kinesis-ingestor-development"
#  kinesis_stream_policy = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
#  project_id            = local.project
#  env                   = local.environment
#  dms_source_name       = "postgres"
#  dms_target_name       = "kinesis"
#  short_name            = "useforce"
#  migration_type        = "full-load-and-cdc"
#  subnet_ids            = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]

#  vpc_role_dependency        = [aws_iam_role.dmsvpcrole]
#  cloudwatch_role_dependency = [aws_iam_role.dms_cloudwatch_logs_role]

#  extra_attributes = "PluginName=PGLOGICAL"

#  availability_zones = {
#    0 = "eu-west-2a"
#  }

#  tags = merge(
#    local.all_tags,
#    {
#      Name          = "${local.project}-dms-use-of-force-ingestor-${local.env}"
#      Resource_Type = "DMS Replication"
#   }
#  )
#}

# S3 Oracle to Nomis SQS Notification # Disabled DPR-287 - TBC
# module "s3_nomis_oracle_sqs" {
#  source                    = "./modules/s3_bucket"
#  create_s3                 = local.setup_buckets
#  name                      = "${local.project}-nomis-cdc-event-${local.environment}"
#  custom_kms_key            = local.s3_kms_arn
#  create_notification_queue = true
#  filter_prefix             = "cdc/"
#  s3_notification_name      = "nomis-cdc-event-notification"
#  sqs_msg_retention_seconds = 1209600

#  tags = merge(
#    local.all_tags,
#    {
#      Name          = "${local.project}-nomis-cdc-event-${local.environment}"
#      Resource_Type = "S3 Bucket"
#    }
#  )
#}

# S3 - CDC Domain Events SQS Notification (DPR-116) # Disabled DPR-287 - TBC
# module "s3_domain_cdc_sqs" {
#  source                    = "./modules/s3_bucket"
#  create_s3                 = local.setup_buckets
#  name                      = "${local.project}-domain-cdc-event-${local.environment}"
#  custom_kms_key            = local.s3_kms_arn
#  create_notification_queue = true
#  filter_prefix             = "cdc/"
#  s3_notification_name      = "domain-cdc-event-notification"
#  sqs_msg_retention_seconds = 1209600

#  tags = merge(
#    local.all_tags,
#    {
#      Name          = "${local.project}-domain-cdc-event-${local.environment}"
#      Resource_Type = "S3 Bucket"
#    }
#  )
#}

# Kinesis Nomis Stream # Commented DPR-287 - TBC
# module "kinesis_nomis_stream" {
#  source                     = "./modules/kinesis_firehose"
#  name                       = "${local.project}-nomis-target-stream-${local.env}"
#  kinesis_source_stream_arn  = module.kinesis_stream_ingestor.kinesis_stream_arn  # KDS Cloud Platform
#  kinesis_source_stream_name = module.kinesis_stream_ingestor.kinesis_stream_name # KDS Cloud Platform
#  target_s3_id               = module.s3_nomis_oracle_sqs.bucket_id
#  target_s3_arn              = module.s3_nomis_oracle_sqs.bucket_arn
#  target_s3_kms              = local.s3_kms_arn
#  target_s3_prefix           = "cdc/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
#  target_s3_error_prefix     = "cdc-error/type=!{firehose:error-output-type}/"
#  aws_account_id             = local.account_id
#  aws_region                 = local.account_region
#  cloudwatch_log_group_name  = "/aws/kinesisfirehose/nomis-target-stream"
#  cloudwatch_log_stream_name = "NomisTargetStream"
#  cloudwatch_logging_enabled = true
#}

# Kinesis cdc domain Stream (DPR-116) # Commented DPR-287 - TBC
# module "kinesis_cdc_domain_stream" {
#  source                     = "./modules/kinesis_firehose"
#  name                       = "${local.project}-cdc-domain-stream-${local.env}"
#  kinesis_source_stream_arn  = module.kinesis_stream_domain_data.kinesis_stream_arn  # KDS Domain Platform
#  kinesis_source_stream_name = module.kinesis_stream_domain_data.kinesis_stream_name # KDS Domain Platform
#  target_s3_id               = module.s3_domain_cdc_sqs.bucket_id
#  target_s3_arn              = module.s3_domain_cdc_sqs.bucket_arn
#  target_s3_kms              = local.s3_kms_arn
#  target_s3_prefix           = "cdc/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
#  target_s3_error_prefix     = "cdc-error/type=!{firehose:error-output-type}/"
#  aws_account_id             = local.account_id
#  aws_region                 = local.account_region
#  cloudwatch_log_group_name  = "/aws/kinesisfirehose/cdc-domain-stream"
#  cloudwatch_log_stream_name = "CdcDomainStream"
#  cloudwatch_logging_enabled = true
#}

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
      name            = "primaryId-Type-Index"
      hash_key        = "primaryId"
      range_key       = "type"
      write_capacity  = 10
      read_capacity   = 10
      projection_type = "ALL"
    },
    {
      name            = "secondaryId-Type-Index"
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

# Dynamo Reporting HUB (DPR-340, DPR-378)
module "dynamo_tab_reporting_hub" {
  source              = "./modules/dynamo_tables"
  create_table        = true
  autoscaling_enabled = false
  name                = "${local.project}-reporting-hub-${local.environment}"

  hash_key    = "leaseKey" # Hash
  range_key   = ""         # Sort
  table_class = "STANDARD"
  ttl_enabled = false

  attributes = [
    {
      name = "leaseKey"
      type = "S"
    }
  ]

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-reporting-hub-${local.environment}"
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