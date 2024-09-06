#### This file can be used to store locals specific to the member account ####
#### DPR Specific ####
locals {
  project              = local.application_data.accounts[local.environment].project_short_id
  analytics_project_id = "analytics"

  other_log_retention_in_days = local.application_data.accounts[local.environment].other_log_retention_in_days

  # Kinesis Agent
  kinesis_agent_autoscale = local.application_data.accounts[local.environment].kinesis_agent_autoscale

  # glue_db                       = local.application_data.accounts[local.environment].glue_db_name
  # glue_db_data_domain           = local.application_data.accounts[local.environment].glue_db_data_domain
  description             = local.application_data.accounts[local.environment].db_description
  create_db               = local.application_data.accounts[local.environment].create_database
  glue_job                = local.application_data.accounts[local.environment].glue_job_name
  create_job              = local.application_data.accounts[local.environment].create_job
  create_sec_conf         = local.application_data.accounts[local.environment].create_security_conf
  env                     = local.environment
  s3_kms_arn              = aws_kms_key.s3.arn
  operational_db_kms_arn  = aws_kms_key.operational_db.arn
  operational_db_kms_id   = aws_kms_key.operational_db.key_id
  kinesis_kms_arn         = aws_kms_key.kinesis-kms-key.arn
  kinesis_kms_id          = data.aws_kms_key.kinesis_kms_key.key_id
  create_bucket           = local.application_data.accounts[local.environment].setup_buckets
  account_id              = data.aws_caller_identity.current.account_id
  account_region          = data.aws_region.current.name
  create_kinesis          = local.application_data.accounts[local.environment].create_kinesis_streams
  kinesis_retention_hours = local.application_data.accounts[local.environment].kinesis_retention_hours
  enable_glue_registry    = local.application_data.accounts[local.environment].create_glue_registries
  setup_buckets           = local.application_data.accounts[local.environment].setup_s3_buckets
  create_glue_connection  = local.application_data.accounts[local.environment].create_glue_connections
  image_id                = local.application_data.accounts[local.environment].ami_image_id
  instance_type           = local.application_data.accounts[local.environment].ec2_instance_type
  create_datamart         = local.application_data.accounts[local.environment].setup_redshift
  redshift_cluster_name   = "${local.application_data.accounts[local.environment].project_short_id}-redshift-${local.environment}"
  kinesis_stream_ingestor = "${local.application_data.accounts[local.environment].project_short_id}-kinesis-ingestor-${local.environment}"

  glue_job_common_log_level = local.application_data.accounts[local.environment].glue_job_common_log_level

  kinesis_endpoint      = "https://kinesis.eu-west-2.amazonaws.com"
  cloud_platform_cidr   = "172.20.0.0/16"
  enable_dpr_cloudtrail = local.application_data.accounts[local.environment].enable_cloud_trail
  generic_lambda        = "${local.project}-generic-lambda"

  lambda_log_retention_in_days = local.application_data.accounts[local.environment].lambda_log_retention_in_days
  enable_generic_lambda_sg     = true # True for all Envs, Common SG Group
  # DMS Specific
  setup_dms_instance                = local.application_data.accounts[local.environment].setup_dms_instance
  enable_replication_task           = local.application_data.accounts[local.environment].enable_dms_replication_task
  setup_fake_data_dms_instance      = local.application_data.accounts[local.environment].setup_fake_data_dms_instance
  enable_fake_data_replication_task = local.application_data.accounts[local.environment].enable_fake_data_dms_replication_task
  # DataMart Specific
  datamart_endpoint = jsondecode(data.aws_secretsmanager_secret_version.datamart.secret_string)["host"]
  datamart_port     = jsondecode(data.aws_secretsmanager_secret_version.datamart.secret_string)["port"]
  datamart_username = jsondecode(data.aws_secretsmanager_secret_version.datamart.secret_string)["username"]
  datamart_password = jsondecode(data.aws_secretsmanager_secret_version.datamart.secret_string)["password"]

  # Athena Federated Query
  federated_query_lambda_memory_mb             = local.application_data.accounts[local.environment].athena_federated_query_lambda_memory_mb
  federated_query_lambda_timeout_seconds       = local.application_data.accounts[local.environment].athena_federated_query_lambda_timeout_seconds
  federated_query_lambda_concurrent_executions = local.application_data.accounts[local.environment].athena_federated_query_lambda_concurrent_executions

  # Glue Job parameters
  glue_placeholder_script_location = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/scripts/digital-prison-reporting-jobs-vLatest.scala"
  glue_jobs_latest_jar_location    = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/jars/digital-prison-reporting-jobs-vLatest-all.jar"
  glue_log_retention_in_days       = local.application_data.accounts[local.environment].glue_log_retention_in_days
  # Reporting Hub Job
  reporting_hub_driver_mem   = local.application_data.accounts[local.environment].reporting_hub_spark_driver_mem
  reporting_hub_executor_mem = local.application_data.accounts[local.environment].reporting_hub_spark_executor_mem
  reporting_hub_worker_type  = local.application_data.accounts[local.environment].reporting_hub_worker_type
  reporting_hub_num_workers  = local.application_data.accounts[local.environment].reporting_hub_num_workers
  reporting_hub_log_level    = local.application_data.accounts[local.environment].reporting_hub_spark_log_level

  reporting_hub_batch_duration_seconds      = local.application_data.accounts[local.environment].reporting_hub_batch_duration_seconds
  reporting_hub_add_idle_time_between_reads = local.application_data.accounts[local.environment].reporting_hub_add_idle_time_between_reads

  reporting_hub_idle_time_between_reads_in_millis = local.application_data.accounts[local.environment].reporting_hub_idle_time_between_reads_in_millis

  reporting_hub_retry_max_attempts    = local.application_data.accounts[local.environment].reporting_hub_retry_max_attempts
  reporting_hub_retry_min_wait_millis = local.application_data.accounts[local.environment].reporting_hub_retry_min_wait_millis
  reporting_hub_retry_max_wait_millis = local.application_data.accounts[local.environment].reporting_hub_retry_max_wait_millis

  reporting_hub_domain_refresh_enabled = local.application_data.accounts[local.environment].reporting_hub_domain_refresh_enabled

  # Reporting Hub Batch Job
  reporting_hub_batch_job_worker_type = local.application_data.accounts[local.environment].reporting_hub_batch_job_worker_type
  reporting_hub_batch_job_num_workers = local.application_data.accounts[local.environment].reporting_hub_batch_job_num_workers
  reporting_hub_batch_job_log_level   = local.application_data.accounts[local.environment].reporting_hub_batch_job_log_level

  reporting_hub_batch_job_schema_cache_max_size = local.application_data.accounts[local.environment].reporting_hub_batch_job_schema_cache_max_size

  reporting_hub_batch_job_retry_max_attempts    = local.application_data.accounts[local.environment].reporting_hub_batch_job_retry_max_attempts
  reporting_hub_batch_job_retry_min_wait_millis = local.application_data.accounts[local.environment].reporting_hub_batch_job_retry_min_wait_millis
  reporting_hub_batch_job_retry_max_wait_millis = local.application_data.accounts[local.environment].reporting_hub_batch_job_retry_max_wait_millis

  # Reporting Hub CDC Job
  reporting_hub_cdc_job_worker_type = local.application_data.accounts[local.environment].reporting_hub_cdc_job_worker_type
  reporting_hub_cdc_job_num_workers = local.application_data.accounts[local.environment].reporting_hub_cdc_job_num_workers
  reporting_hub_cdc_job_log_level   = local.application_data.accounts[local.environment].reporting_hub_cdc_job_log_level

  reporting_hub_cdc_job_schema_cache_max_size = local.application_data.accounts[local.environment].reporting_hub_cdc_job_schema_cache_max_size

  reporting_hub_cdc_job_retry_max_attempts    = local.application_data.accounts[local.environment].reporting_hub_cdc_job_retry_max_attempts
  reporting_hub_cdc_job_retry_min_wait_millis = local.application_data.accounts[local.environment].reporting_hub_cdc_job_retry_min_wait_millis
  reporting_hub_cdc_job_retry_max_wait_millis = local.application_data.accounts[local.environment].reporting_hub_cdc_job_retry_max_wait_millis

  # Refresh Job
  refresh_job_worker_type = local.application_data.accounts[local.environment].refresh_job_worker_type
  refresh_job_num_workers = local.application_data.accounts[local.environment].refresh_job_num_workers
  refresh_job_log_level   = local.application_data.accounts[local.environment].refresh_job_log_level

  # Common Maintenance Job settings
  maintenance_job_retry_max_attempts    = local.application_data.accounts[local.environment].maintenance_job_retry_max_attempts
  maintenance_job_retry_min_wait_millis = local.application_data.accounts[local.environment].maintenance_job_retry_min_wait_millis
  maintenance_job_retry_max_wait_millis = local.application_data.accounts[local.environment].maintenance_job_retry_max_wait_millis

  # Compact Raw Job
  compact_raw_job_worker_type = local.application_data.accounts[local.environment].compact_raw_job_worker_type
  compact_raw_job_num_workers = local.application_data.accounts[local.environment].compact_raw_job_num_workers
  compact_raw_job_log_level   = local.application_data.accounts[local.environment].compact_raw_job_log_level
  compact_raw_job_schedule    = local.application_data.accounts[local.environment].compact_raw_job_schedule

  # Compact Structured Job
  compact_structured_job_worker_type = local.application_data.accounts[local.environment].compact_structured_job_worker_type
  compact_structured_job_num_workers = local.application_data.accounts[local.environment].compact_structured_job_num_workers
  compact_structured_job_log_level   = local.application_data.accounts[local.environment].compact_structured_job_log_level
  compact_structured_job_schedule    = local.application_data.accounts[local.environment].compact_structured_job_schedule

  # Compact Curated Job
  compact_curated_job_worker_type = local.application_data.accounts[local.environment].compact_curated_job_worker_type
  compact_curated_job_num_workers = local.application_data.accounts[local.environment].compact_curated_job_num_workers
  compact_curated_job_log_level   = local.application_data.accounts[local.environment].compact_curated_job_log_level
  compact_curated_job_schedule    = local.application_data.accounts[local.environment].compact_curated_job_schedule

  # Compact Domain Job
  compact_domain_job_worker_type = local.application_data.accounts[local.environment].compact_domain_job_worker_type
  compact_domain_job_num_workers = local.application_data.accounts[local.environment].compact_domain_job_num_workers
  compact_domain_job_log_level   = local.application_data.accounts[local.environment].compact_domain_job_log_level
  compact_domain_job_schedule    = local.application_data.accounts[local.environment].compact_domain_job_schedule

  # Retention (vacuum) Raw Job
  retention_raw_job_worker_type = local.application_data.accounts[local.environment].retention_raw_job_worker_type
  retention_raw_job_num_workers = local.application_data.accounts[local.environment].retention_raw_job_num_workers
  retention_raw_job_log_level   = local.application_data.accounts[local.environment].retention_raw_job_log_level
  retention_raw_job_schedule    = local.application_data.accounts[local.environment].retention_raw_job_schedule

  # Retention (vacuum) Structured Job
  retention_structured_job_worker_type = local.application_data.accounts[local.environment].retention_structured_job_worker_type
  retention_structured_job_num_workers = local.application_data.accounts[local.environment].retention_structured_job_num_workers
  retention_structured_job_log_level   = local.application_data.accounts[local.environment].retention_structured_job_log_level
  retention_structured_job_schedule    = local.application_data.accounts[local.environment].retention_structured_job_schedule

  # Retention (vacuum) Curated Job
  retention_curated_job_worker_type = local.application_data.accounts[local.environment].retention_curated_job_worker_type
  retention_curated_job_num_workers = local.application_data.accounts[local.environment].retention_curated_job_num_workers
  retention_curated_job_log_level   = local.application_data.accounts[local.environment].retention_curated_job_log_level
  retention_curated_job_schedule    = local.application_data.accounts[local.environment].retention_curated_job_schedule

  # Retention (vacuum) Domain Job
  retention_domain_job_worker_type = local.application_data.accounts[local.environment].retention_domain_job_worker_type
  retention_domain_job_num_workers = local.application_data.accounts[local.environment].retention_domain_job_num_workers
  retention_domain_job_log_level   = local.application_data.accounts[local.environment].retention_domain_job_log_level
  retention_domain_job_schedule    = local.application_data.accounts[local.environment].retention_domain_job_schedule

  # Hive Table Creation Job
  hive_table_creation_job_schema_cache_max_size = local.application_data.accounts[local.environment].hive_table_creation_job_schema_cache_max_size

  # Common Policies
  kms_read_access_policy = "${local.project}_kms_read_policy"
  s3_read_access_policy  = "${local.project}_s3_read_policy"
  s3_read_write_policy   = "${local.project}_s3_read_write_policy"
  apigateway_get_policy  = "${local.project}_apigateway_get_policy"
  invoke_lambda_policy   = "${local.project}_invoke_lambda_policy"

  trigger_glue_job_policy = "${local.project}_start_glue_job_policy"
  start_dms_task_policy   = "${local.project}_start_dms_task_policy"

  s3_all_object_actions_policy = "${local.project}_s3_all_object_actions_policy"
  all_state_machine_policy     = "${local.project}_all_state_machine_policy"
  dynamo_db_access_policy      = "${local.project}_dynamo_db_access_policy"

  # DPR Alerts
  enable_slack_alerts     = local.application_data.accounts[local.environment].enable_slack_alerts
  enable_pagerduty_alerts = local.application_data.accounts[local.environment].enable_pagerduty_alerts

  # Domain Builder, Variables
  dpr_vpc                        = data.aws_vpc.shared.id
  dpr_subnets                    = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  domain_registry                = "${local.project}-domain-registry-${local.environment}"
  rds_kms_arn                    = aws_kms_key.rds.arn
  enable_domain_builder_rds      = local.application_data.accounts[local.environment].enable_domain_builder_rds
  rds_dbuilder_name              = "${local.project}-backend-rds"
  rds_dbuilder_db_identifier     = "${local.project}_domain_builder"
  rds_dbuilder_inst_class        = "db.t3.small"
  rds_dbuilder_store_type        = "gp2"
  rds_dbuilder_init_size         = 10
  rds_dbuilder_max_size          = 50
  rds_dbuilder_parameter_group   = "postgres14"
  rds_dbuilder_port              = 5432
  rds_dbuilder_user              = "domain_builder"
  enable_dbuilder_lambda         = local.application_data.accounts[local.environment].enable_domain_builder_lambda
  lambda_dbuilder_name           = "${local.project}-domain-builder-backend-api"
  lambda_dbuilder_runtime        = "java11"
  lambda_dbuilder_tracing        = "Active"
  lambda_dbuilder_handler        = "io.micronaut.function.aws.proxy.MicronautLambdaHandler"
  lambda_dbuilder_code_s3_bucket = module.s3_artifacts_store.bucket_id
  lambda_dbuilder_code_s3_key    = "build-artifacts/domain-builder/jars/domain-builder-backend-api-vLatest-all.jar"
  lambda_dbuilder_policies = [
    "arn:aws:iam::${local.account_id}:policy/${local.s3_read_access_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.project}-domain-builder-preview-policy",
    "arn:aws:iam::${local.account_id}:policy/${local.project}-domain-builder-publish-policy"
  ]
  enable_domain_builder_agent    = local.application_data.accounts[local.environment].enable_domain_builder_agent
  enable_dbuilder_flyway_lambda  = local.application_data.accounts[local.environment].enable_dbuilder_flyway_lambda
  flyway_dbuilder_name           = "${local.project}-domain-builder-flyway"
  flyway_dbuilder_code_s3_bucket = module.s3_artifacts_store.bucket_id
  flyway_dbuilder_code_s3_key    = "third-party/flyway-generic/flyway-lambda-0.9.jar"
  flyway_dbuilder_handler        = "com.geekoosh.flyway.FlywayHandler"
  flyway_dbuilder_runtime        = "java11"
  flyway_dbuilder_policies       = ["arn:aws:iam::${local.account_id}:policy/${local.s3_read_access_policy}", data.aws_iam_policy.rds_full_access.arn, ]
  flyway_dbuilder_tracing        = "Active"
  enable_dbuilder_serverless_gw  = local.application_data.accounts[local.environment].enable_dbuilder_serverless_gw
  include_dbuilder_gw_vpclink    = local.application_data.accounts[local.environment].include_dbuilder_gw_vpclink
  serverless_gw_dbuilder_name    = "${local.project}-serverless-lambda"
  domain_preview_database        = "curated"
  domain_preview_s3_bucket       = module.s3_domain_preview_bucket.bucket_id
  domain_preview_workgroup       = "primary"

  # Transfer Component
  enable_transfercomp_lambda         = local.application_data.accounts[local.environment].enable_transfer_component_lambda
  lambda_transfercomp_name           = "${local.project}-transfer-component"
  lambda_transfercomp_ods_name       = "${local.project}-transfer-component-operational-datastore"
  lambda_transfercomp_runtime        = "java11"
  lambda_transfercomp_tracing        = "Active"
  lambda_transfercomp_handler        = "com.geekoosh.flyway.FlywayHandler"
  lambda_transfercomp_code_s3_bucket = module.s3_artifacts_store.bucket_id
  lambda_transfercomp_code_s3_key    = "third-party/flyway-generic/flyway-lambda-0.9.jar"
  lambda_transfercomp_policies       = ["arn:aws:iam::${local.account_id}:policy/${local.s3_read_access_policy}", ]
  create_transfercomp_lambda_layer   = local.application_data.accounts[local.environment].create_transfer_component_lambda_layer
  lambda_transfercomp_layer_name     = "${local.project}-redhift-jdbc-dependency-layer"

  # Redshift Expired External Table Remover Lambda
  lambda_redshift_table_expiry_enabled        = true
  lambda_redshift_table_expiry_name           = "${local.project}-redshift-expired-external-table-remover"
  lambda_redshift_table_expiry_runtime        = "java11"
  lambda_redshift_table_expiry_tracing        = "Active"
  lambda_redshift_table_expiry_handler        = "uk.gov.justice.digital.lambda.RedShiftTableExpiryLambda::handleRequest"
  lambda_redshift_table_expiry_code_s3_bucket = module.s3_artifacts_store.bucket_id
  lambda_redshift_table_expiry_jar_version    = "v0.0.12"
  lambda_redshift_table_expiry_code_s3_key = (
    local.env == "production" 
    ? "s3://dpr-artifact-store-production/build-artifacts/digital-prison-reporting-lambdas/jars/digital-prison-reporting-lambdas-${local.lambda_redshift_table_expiry_jar_version}.rel-all.jar" 
    : "build-artifacts/digital-prison-reporting-lambdas/jars/digital-prison-reporting-lambdas-${local.lambda_redshift_table_expiry_jar_version}-all.jar"
  )
  lambda_redshift_table_expiry_policies = [
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
    aws_iam_policy.redshift_dataapi_cross_policy.arn,
  ]
  lambda_redshift_table_expiry_secret_arn          = module.datamart.credential_secret_arn
  lambda_redshift_table_expiry_cluster_id          = module.datamart.cluster_id
  lambda_redshift_table_expiry_database_name       = module.datamart.cluster_database_name
  lambda_redshift_table_expiry_schedule_expression = "rate(1 hour)"
  lambda_redshift_table_expiry_seconds             = "86400"
  lambda_redshift_table_expiry_timeout_seconds     = 900
  lambda_redshift_table_expiry_memory_size         = 1024

  reporting_lambda_code_s3_key = "build-artifacts/digital-prison-reporting-lambdas/jars/digital-prison-reporting-lambdas-vLatest-all.jar"

  # s3 transfer
  scheduled_s3_file_transfer_retention_period_amount = local.application_data.accounts[local.environment].scheduled_s3_file_transfer_retention_period_amount
  scheduled_s3_file_transfer_retention_period_unit   = local.application_data.accounts[local.environment].scheduled_s3_file_transfer_retention_period_unit

  # step function notification lambda
  step_function_notification_lambda_handler = "uk.gov.justice.digital.lambda.StepFunctionDMSNotificationLambda::handleRequest"
  step_function_notification_lambda_policies = [
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.all_state_machine_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.dynamo_db_access_policy}"
  ]

  # Datamart
  create_scheduled_action_iam_role = local.application_data.accounts[local.environment].setup_scheduled_action_iam_role
  create_redshift_schedule         = local.application_data.accounts[local.environment].setup_redshift_schedule

  # Enable CW alarms
  enable_cw_alarm                   = local.application_data.accounts[local.environment].alarms.setup_cw_alarms
  enable_redshift_health_check      = local.application_data.accounts[local.environment].alarms.redshift.health_check.enable
  thrld_redshift_health_check       = local.application_data.accounts[local.environment].alarms.redshift.health_check.threshold
  period_redshift_health_check      = local.application_data.accounts[local.environment].alarms.redshift.health_check.period
  enable_dms_stop_check             = local.application_data.accounts[local.environment].alarms.dms.stop_check.enable
  thrld_dms_stop_check              = local.application_data.accounts[local.environment].alarms.dms.stop_check.threshold
  period_dms_stop_check             = local.application_data.accounts[local.environment].alarms.dms.stop_check.period
  enable_dms_start_check            = local.application_data.accounts[local.environment].alarms.dms.start_check.enable
  thrld_dms_start_check             = local.application_data.accounts[local.environment].alarms.dms.start_check.threshold
  period_dms_start_check            = local.application_data.accounts[local.environment].alarms.dms.start_check.period
  enable_dms_cpu_check              = local.application_data.accounts[local.environment].alarms.dms.cpu_check.enable
  thrld_dms_cpu_check               = local.application_data.accounts[local.environment].alarms.dms.cpu_check.threshold
  period_dms_cpu_check              = local.application_data.accounts[local.environment].alarms.dms.cpu_check.period
  enable_dms_freemem_check          = local.application_data.accounts[local.environment].alarms.dms.freemem_check.enable
  thrld_dms_freemem_check           = local.application_data.accounts[local.environment].alarms.dms.freemem_check.threshold
  period_dms_freemem_check          = local.application_data.accounts[local.environment].alarms.dms.freemem_check.period
  enable_dms_freeablemem_check      = local.application_data.accounts[local.environment].alarms.dms.freeablemem_check.enable
  thrld_dms_freeablemem_check       = local.application_data.accounts[local.environment].alarms.dms.freeablemem_check.threshold
  period_dms_freeablemem_check      = local.application_data.accounts[local.environment].alarms.dms.freeablemem_check.period
  enable_dms_swapusage_check        = local.application_data.accounts[local.environment].alarms.dms.swapusage_check.enable
  thrld_dms_swapusage_check         = local.application_data.accounts[local.environment].alarms.dms.swapusage_check.threshold
  period_dms_swapusage_check        = local.application_data.accounts[local.environment].alarms.dms.swapusage_check.period
  enable_dms_network_trans_tp_check = local.application_data.accounts[local.environment].alarms.dms.network_trans_tp_check.enable
  thrld_dms_network_trans_tp_check  = local.application_data.accounts[local.environment].alarms.dms.network_trans_tp_check.threshold
  period_dms_network_trans_tp_check = local.application_data.accounts[local.environment].alarms.dms.network_trans_tp_check.period
  enable_dms_network_rec_tp_check   = local.application_data.accounts[local.environment].alarms.dms.network_rec_tp_check.enable
  thrld_dms_network_rec_tp_check    = local.application_data.accounts[local.environment].alarms.dms.network_rec_tp_check.threshold
  period_dms_network_rec_tp_check   = local.application_data.accounts[local.environment].alarms.dms.network_rec_tp_check.period
  enable_dms_cdc_src_lat_check      = local.application_data.accounts[local.environment].alarms.dms.cdc_src_lat_check.enable
  thrld_dms_cdc_src_lat_check       = local.application_data.accounts[local.environment].alarms.dms.cdc_src_lat_check.threshold
  period_dms_cdc_src_lat_check      = local.application_data.accounts[local.environment].alarms.dms.cdc_src_lat_check.period
  enable_dms_cdc_targ_lat_check     = local.application_data.accounts[local.environment].alarms.dms.cdc_targ_lat_check.enable
  thrld_dms_cdc_targ_lat_check      = local.application_data.accounts[local.environment].alarms.dms.cdc_targ_lat_check.threshold
  period_dms_cdc_targ_lat_check     = local.application_data.accounts[local.environment].alarms.dms.cdc_targ_lat_check.period
  enable_dms_cdc_inc_events_check   = local.application_data.accounts[local.environment].alarms.dms.cdc_inc_events_check.enable
  thrld_dms_cdc_inc_events_check    = local.application_data.accounts[local.environment].alarms.dms.cdc_inc_events_check.threshold
  period_dms_cdc_inc_events_check   = local.application_data.accounts[local.environment].alarms.dms.cdc_inc_events_check.period

  # CW Insights
  enable_cw_insights = local.application_data.accounts[local.environment].setup_cw_insights

  # Setup Athena Workgroups
  setup_dpr_generic_athena_workgroup       = local.application_data.accounts[local.environment].dpr_generic_athena_workgroup
  setup_analytics_generic_athena_workgroup = local.application_data.accounts[local.environment].analytics_generic_athena_workgroup

  # Sonatype Secrets
  setup_sonatype_secrets = local.application_data.accounts[local.environment].setup_sonatype_secrets

  # Nomis Secrets PlaceHolder
  nomis_secrets_placeholder = {
    db_name  = "nomis"
    password = "placeholder"
    # We need to duplicate the username with 'user' and 'username' keys
    user     = "placeholder"
    username = "placeholder"
    endpoint = "0.0.0.0" # In dev this is always manually set to the static_private_ip of the ec2_kinesis_agent acting as a tunnel to NOMIS
    port     = "1521"
  }

  # Bodmis Secrets PlaceHolder
  bodmis_secrets_placeholder = {
    db_name  = "bodmis"
    password = "placeholder"
    user     = "placeholder"
    username = "placeholder"
    endpoint = "0.0.0.0" # In dev this is always manually set to the static_private_ip of the ec2_kinesis_agent acting as a tunnel to NOMIS
    port     = "1522"
  }

  # DPS Secrets PlaceHolder
  dps_domains_list = local.application_data.accounts[local.environment].dps_domains
  dps_secrets_placeholder = {
    db_name  = "dps"
    password = "placeholder"
    user     = "placeholder"
    endpoint = "0.0.0.0"
    port     = "5432"
  }

  # Operational DataStore Secrets PlaceHolder
  operational_datastore_secrets_placeholder = {
    username = "placeholder"
    password = "placeholder"
  }

  # biprws Secrets Placeholder
  enable_biprws_secrets = local.application_data.accounts[local.environment].biprws.enable
  biprws_secrets_placeholder = {
    busobj-converter = "placeholder"
    endpoint         = local.application_data.accounts[local.environment].biprws.endpoint
    endpoint_type    = local.application_data.accounts[local.environment].biprws.endpoint_type
  }

  # cp_k8s_secrets_placeholder
  enable_cp_k8s_secrets = local.application_data.accounts[local.environment].enable_cp_k8s_secrets
  cp_k8s_secrets_placeholder = {
    cloud_platform_k8s_token           = "placeholder"
    cloud_platform_certificate_auth    = "placeholder"
    cloud_platform_k8s_server          = "placeholder"
    cloud_platform_k8s_cluster_name    = "placeholder"
    cloud_platform_k8s_cluster_context = "placeholder"
  }

  # cp_bodmis_k8s_secrets_placeholder
  enable_cp_bodmis_k8s_secrets = local.application_data.accounts[local.environment].enable_cp_bodmis_k8s_secrets
  cp_bodmis_k8s_secrets_placeholder = {
    cloud_platform_k8s_token           = "placeholder"
    cloud_platform_certificate_auth    = "placeholder"
    cloud_platform_k8s_server          = "placeholder"
    cloud_platform_k8s_cluster_name    = "placeholder"
    cloud_platform_k8s_cluster_context = "placeholder"
  }

  # Analytics Platform, DBT Secrets
  enable_dbt_k8s_secrets = local.application_data.accounts[local.environment].enable_dbt_k8s_secrets
  dbt_k8s_secrets_placeholder = {
    oidc_cluster_identifier = "placeholder"
  }

  sonatype_secrets_placeholder = {
    user     = "placeholder"
    password = "placeholder"
  }

  # Evaluate Redshift Secrets and Populate
  redshift_secrets = {
    dbClusterIdentifier = "dpr-redshift-${local.project}"
    engine              = "redshift"
    host                = module.datamart.cluster_endpoint
    password            = module.datamart.redshift_master_password
    port                = "5439"
    username            = module.datamart.redshift_master_user
  }

  analytical_platform_share = can(local.application_data.accounts[local.environment].analytical_platform_share) ? { for share in local.application_data.accounts[local.environment].analytical_platform_share : share.target_account_name => share } : {}

  # Observability Platform
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      observability_platform_account_id = local.environment_management.account_ids["observability-platform-development"]
    }
    test = {
      observability_platform_account_id = local.environment_management.account_ids["observability-platform-development"]
    }
    preproduction = {
      observability_platform_account_id = local.environment_management.account_ids["observability-platform-development"]
    }
    production = {
      observability_platform_account_id = local.environment_management.account_ids["observability-platform-production"]
    }
  }


  all_tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}
