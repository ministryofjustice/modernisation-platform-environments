#### This file can be used to store locals specific to the member account ####
#### DPR Specific ####
locals {

  is_dev_or_test       = local.is-development || local.is-test
  is_non_prod          = !local.is-production
  project              = local.application_data.accounts[local.environment].project_short_id
  analytics_project_id = "analytics"

  # custom event bus
  event_bus_dpr = "dpr-event_bus"

  # default event bus
  default_event_bus = "default"

  other_log_retention_in_days = local.application_data.accounts[local.environment].other_log_retention_in_days

  # Bastion Host
  bastion_host_autoscale = local.application_data.accounts[local.environment].bastion_host_autoscale

  # glue_db                       = local.application_data.accounts[local.environment].glue_db_name
  # glue_db_data_domain           = local.application_data.accounts[local.environment].glue_db_data_domain
  description            = local.application_data.accounts[local.environment].db_description
  create_db              = local.application_data.accounts[local.environment].create_database
  glue_job               = local.application_data.accounts[local.environment].glue_job_name
  create_job             = local.application_data.accounts[local.environment].create_job
  create_sec_conf        = local.application_data.accounts[local.environment].create_security_conf
  env                    = local.environment
  s3_kms_arn             = aws_kms_key.s3.arn
  operational_db_kms_arn = aws_kms_key.operational_db.arn
  operational_db_kms_id  = aws_kms_key.operational_db.key_id
  create_bucket          = local.application_data.accounts[local.environment].setup_buckets
  account_id             = data.aws_caller_identity.current.account_id
  account_region         = data.aws_region.current.name
  enable_glue_registry   = local.application_data.accounts[local.environment].create_glue_registries
  setup_buckets          = local.application_data.accounts[local.environment].setup_s3_buckets
  create_glue_connection = local.application_data.accounts[local.environment].create_glue_connections
  image_id               = local.application_data.accounts[local.environment].ami_image_id
  instance_type          = local.application_data.accounts[local.environment].ec2_instance_type
  create_datamart        = local.application_data.accounts[local.environment].setup_redshift
  redshift_cluster_name  = "${local.application_data.accounts[local.environment].project_short_id}-redshift-${local.environment}"

  glue_job_common_log_level = local.application_data.accounts[local.environment].glue_job_common_log_level
  glue_job_version          = local.application_data.accounts[local.environment].glue_job_version

  # Flag for whether jobs that access the operational datastore have this feature turned on or not
  enable_operational_datastore_job_access = local.application_data.accounts[local.environment].enable_operational_datastore_job_access

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
  lambda_oracle_handler                        = "com.amazonaws.athena.connectors.oracle.OracleMuxCompositeHandler"
  athena_oracle_connector_type                 = "oracle"

  # Glue Job parameters
  glue_placeholder_script_location = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/scripts/digital-prison-reporting-jobs-vLatest.scala"
  glue_jobs_latest_jar_location    = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/jars/digital-prison-reporting-jobs-v1.0.125-dev.22+DHS-469-glue-v5-upgrade.f645b453-all.jar"
  glue_log_retention_in_days       = local.application_data.accounts[local.environment].glue_log_retention_in_days

  # Common Maintenance Job settings
  maintenance_job_retry_max_attempts    = local.application_data.accounts[local.environment].maintenance_job_retry_max_attempts
  maintenance_job_retry_min_wait_millis = local.application_data.accounts[local.environment].maintenance_job_retry_min_wait_millis
  maintenance_job_retry_max_wait_millis = local.application_data.accounts[local.environment].maintenance_job_retry_max_wait_millis

  # Compact Job
  compact_job_worker_type = local.application_data.accounts[local.environment].compact_job_worker_type
  compact_job_num_workers = local.application_data.accounts[local.environment].compact_job_num_workers
  compact_job_log_level   = local.application_data.accounts[local.environment].compact_job_log_level

  # Retention (vacuum) Job
  retention_job_worker_type = local.application_data.accounts[local.environment].retention_job_worker_type
  retention_job_num_workers = local.application_data.accounts[local.environment].retention_job_num_workers
  retention_job_log_level   = local.application_data.accounts[local.environment].retention_job_log_level

  # Hive Table Creation Job
  hive_table_creation_job_schema_cache_max_size = local.application_data.accounts[local.environment].hive_table_creation_job_schema_cache_max_size

  # Common Policies
  kms_read_access_policy     = "${local.project}_kms_read_policy"
  s3_read_access_policy      = "${local.project}_s3_read_policy"
  s3_read_write_policy       = "${local.project}_s3_read_write_policy"
  apigateway_get_policy      = "${local.project}_apigateway_get_policy"
  invoke_lambda_policy       = "${local.project}_invoke_lambda_policy"
  secretsmanager_read_policy = "${local.project}_secretsmanager_read_policy"


  trigger_glue_job_policy = "${local.project}_start_glue_job_policy"
  start_dms_task_policy   = "${local.project}_start_dms_task_policy"

  s3_all_object_actions_policy = "${local.project}_s3_all_object_actions_policy"
  all_state_machine_policy     = "${local.project}_all_state_machine_policy"
  dynamo_db_access_policy      = "${local.project}_dynamo_db_access_policy"

  # DPR Alerts
  enable_slack_alerts     = local.application_data.accounts[local.environment].enable_slack_alerts
  enable_pagerduty_alerts = local.application_data.accounts[local.environment].enable_pagerduty_alerts

  enable_dms_failure_alerts = local.application_data.accounts[local.environment].enable_dms_failure_alerts

  # DPR RDS Database
  enable_dpr_rds_db              = local.application_data.accounts[local.environment].dpr_rds_db.enable
  create_rds_replica             = local.application_data.accounts[local.environment].dpr_rds_db.create_replica
  dpr_rds_engine                 = local.application_data.accounts[local.environment].dpr_rds_db.engine
  dpr_rds_engine_version         = local.application_data.accounts[local.environment].dpr_rds_db.engine_version
  dpr_rds_init_size              = local.application_data.accounts[local.environment].dpr_rds_db.init_size
  dpr_rds_max_size               = local.application_data.accounts[local.environment].dpr_rds_db.max_size
  dpr_rds_name                   = local.application_data.accounts[local.environment].dpr_rds_db.name
  dpr_rds_db_identifier          = local.application_data.accounts[local.environment].dpr_rds_db.db_identifier
  dpr_rds_inst_class             = local.application_data.accounts[local.environment].dpr_rds_db.inst_class
  dpr_rds_user                   = local.application_data.accounts[local.environment].dpr_rds_db.user
  dpr_rds_store_type             = local.application_data.accounts[local.environment].dpr_rds_db.store_type
  dpr_rds_parameter_group_family = local.application_data.accounts[local.environment].dpr_rds_db.parameter_group_family
  dpr_rds_parameter_group_name   = local.application_data.accounts[local.environment].dpr_rds_db.parameter_group_name

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
  rds_dbuilder_parameter_group   = local.application_data.accounts[local.environment].domain_builder_rds_parameter_group
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
  lambda_redshift_table_expiry_jar_version    = "v0.0.20"
  lambda_redshift_table_expiry_code_s3_key = (
    local.env == "production" || local.env == "preproduction"
    ? "build-artifacts/digital-prison-reporting-lambdas/jars/digital-prison-reporting-lambdas-${local.lambda_redshift_table_expiry_jar_version}.rel-all.jar"
    : "build-artifacts/digital-prison-reporting-lambdas/jars/digital-prison-reporting-lambdas-${local.lambda_redshift_table_expiry_jar_version}-all.jar"
  )
  lambda_redshift_table_expiry_policies = [
    "arn:aws:iam::${local.account_id}:policy/${local.s3_read_access_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
    aws_iam_policy.redshift_dataapi_cross_policy.arn,
  ]
  lambda_redshift_table_expiry_secret_arn          = module.datamart.credential_secret_arn
  lambda_redshift_table_expiry_cluster_id          = module.datamart.cluster_id
  lambda_redshift_table_expiry_database_name       = module.datamart.cluster_database_name
  lambda_redshift_table_expiry_schedule_expression = "rate(1 hour)"
  lambda_redshift_table_expiry_seconds             = (local.application_data.accounts[local.environment].redshift_table_expiry_days * 86400)
  lambda_redshift_table_expiry_timeout_seconds     = 900
  lambda_redshift_table_expiry_memory_size         = 1024

  # Scheduled Dataset Lambda
  lambda_scheduled_dataset_enabled        = local.application_data.accounts[local.environment].enable_scheduled_dataset_lambda
  lambda_scheduled_dataset_name           = "${local.project}-scheduled-dataset"
  lambda_scheduled_dataset_runtime        = "java21"
  lambda_scheduled_dataset_tracing        = "Active"
  lambda_scheduled_dataset_handler        = "uk.gov.justice.digital.hmpps.scheduled.lambda.ReportSchedulerLambda::handleRequest"
  lambda_scheduled_dataset_code_s3_bucket = module.s3_artifacts_store.bucket_id
  lambda_scheduled_dataset_jar_version    = local.application_data.accounts[local.environment].scheduled_dataset_lambda_version
  lambda_scheduled_dataset_code_s3_key    = "build-artifacts/hmpps-dpr-scheduled-dataset-lambda/jars/hmpps-dpr-scheduled-dataset-lambda-${local.lambda_scheduled_dataset_jar_version}-all.jar"
  lambda_scheduled_dataset_policies = [
    "arn:aws:iam::${local.account_id}:policy/${local.s3_read_access_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
    aws_iam_policy.redshift_dataapi_cross_policy.arn,
    aws_iam_policy.dpd_table_read_policy.arn
  ]
  lambda_scheduled_dataset_secret_arn          = module.datamart.credential_secret_arn
  lambda_scheduled_dataset_cluster_id          = module.datamart.cluster_id
  lambda_scheduled_dataset_database_name       = module.datamart.cluster_database_name
  lambda_scheduled_dataset_dpd_ddb_table_arn   = module.dynamo_table_dpd.dynamodb_table_arn
  lambda_scheduled_dataset_schedule_expression = "rate(1 hour)"
  lambda_scheduled_dataset_timeout_seconds     = 900
  lambda_scheduled_dataset_memory_size         = 1024

  # Generate Dataset Lambda
  lambda_generate_dataset_enabled        = local.application_data.accounts[local.environment].enable_generate_dataset_lambda
  lambda_generate_dataset_name           = "${local.project}-generate-dataset"
  lambda_generate_dataset_runtime        = "java21"
  lambda_generate_dataset_tracing        = "Active"
  lambda_generate_dataset_handler        = "uk.gov.justice.digital.hmpps.scheduled.lambda.DatasetGenerateLambda::handleRequest"
  lambda_generate_dataset_code_s3_bucket = module.s3_artifacts_store.bucket_id
  lambda_generate_dataset_jar_version    = local.application_data.accounts[local.environment].scheduled_dataset_lambda_version
  lambda_generate_dataset_code_s3_key    = "build-artifacts/hmpps-dpr-scheduled-dataset-lambda/jars/hmpps-dpr-scheduled-dataset-lambda-${local.lambda_generate_dataset_jar_version}-all.jar"
  lambda_generate_dataset_policies = [
    "arn:aws:iam::${local.account_id}:policy/${local.s3_read_access_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
    aws_iam_policy.redshift_dataapi_cross_policy.arn,
    aws_iam_policy.dpd_table_read_policy.arn
  ]
  lambda_generate_dataset_secret_arn        = module.datamart.credential_secret_arn
  lambda_generate_dataset_cluster_id        = module.datamart.cluster_id
  lambda_generate_dataset_database_name     = module.datamart.cluster_database_name
  lambda_generate_dataset_dpd_ddb_table_arn = module.dynamo_table_dpd.dynamodb_table_arn
  lambda_generate_dataset_timeout_seconds   = 900
  lambda_generate_dataset_memory_size       = 1024

  s3_redshift_table_expiry_days = local.application_data.accounts[local.environment].redshift_table_expiry_days + 1

  reporting_lambda_code_s3_key = "build-artifacts/digital-prison-reporting-lambdas/jars/digital-prison-reporting-lambdas-vLatest-all.jar"

  # Multiphase Query Manager Lambda
  lambda_multiphase_query_enabled        = local.application_data.accounts[local.environment].enable_multiphase_query_lambda
  lambda_multiphase_query_name           = "${local.project}-multiphase-query"
  lambda_multiphase_query_runtime        = "java21"
  lambda_multiphase_query_tracing        = "Active"
  lambda_multiphase_query_handler        = "uk.gov.justice.digital.hmpps.multiphasequery.ManageAthenaAsyncQueries::handleRequest"
  lambda_multiphase_query_code_s3_bucket = module.s3_artifacts_store.bucket_id
  lambda_multiphase_query_jar_version    = local.application_data.accounts[local.environment].multiphase_query_lambda_version
  lambda_multiphase_query_code_s3_key    = "build-artifacts/hmpps-dpr-multiphase-query-lambda/jars/hmpps-dpr-multiphase-query-lambda-${local.lambda_multiphase_query_jar_version}-all.jar"
  lambda_multiphase_query_policies = [
    "arn:aws:iam::${local.account_id}:policy/${local.s3_read_access_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
    aws_iam_policy.redshift_dataapi_cross_policy.arn,
    aws_iam_policy.athena_api_cross_policy.arn,
    aws_iam_policy.glue_catalog_readonly.arn
  ]
  lambda_multiphase_query_secret_arn      = module.datamart.credential_secret_arn
  lambda_multiphase_query_cluster_id      = module.datamart.cluster_id
  lambda_multiphase_query_database_name   = module.datamart.cluster_database_name
  lambda_multiphase_query_timeout_seconds = 900
  lambda_multiphase_query_memory_size     = 1024

  # Multiphase Cleanup Lambda
  lambda_multiphase_cleanup_enabled        = local.application_data.accounts[local.environment].enable_multiphase_cleanup_lambda
  lambda_multiphase_cleanup_name           = "${local.project}-multiphase-cleanup"
  lambda_multiphase_cleanup_runtime        = "java21"
  lambda_multiphase_cleanup_tracing        = "Active"
  lambda_multiphase_cleanup_handler        = "uk.gov.justice.digital.hmpps.multiphasecleanup.MultiphaseCleanUpService::handleRequest"
  lambda_multiphase_cleanup_code_s3_bucket = module.s3_artifacts_store.bucket_id
  lambda_multiphase_cleanup_jar_version    = local.application_data.accounts[local.environment].multiphase_cleanup_lambda_version
  lambda_multiphase_cleanup_code_s3_key    = "build-artifacts/hmpps-dpr-multiphase-cleanup-lambda/jars/hmpps-dpr-multiphase-cleanup-lambda-${local.lambda_multiphase_cleanup_jar_version}-all.jar"
  lambda_multiphase_cleanup_policies = [
    "arn:aws:iam::${local.account_id}:policy/${local.s3_read_access_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
    aws_iam_policy.redshift_dataapi_cross_policy.arn
  ]
  lambda_multiphase_cleanup_secret_arn          = module.datamart.credential_secret_arn
  lambda_multiphase_cleanup_cluster_id          = module.datamart.cluster_id
  lambda_multiphase_cleanup_database_name       = module.datamart.cluster_database_name
  lambda_multiphase_cleanup_timeout_seconds     = 900
  lambda_multiphase_cleanup_memory_size         = 1024
  lambda_multiphase_cleanup_schedule_expression = "rate(1 day)"

  # s3 transfer
  scheduled_s3_file_transfer_retention_period_amount = local.application_data.accounts[local.environment].scheduled_s3_file_transfer_retention_period_amount
  scheduled_s3_file_transfer_retention_period_unit   = local.application_data.accounts[local.environment].scheduled_s3_file_transfer_retention_period_unit
  scheduled_file_transfer_use_default_parallelism    = local.application_data.accounts[local.environment].scheduled_file_transfer_use_default_parallelism
  scheduled_file_transfer_parallelism                = local.application_data.accounts[local.environment].scheduled_file_transfer_parallelism

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

  create_postgres_tickle_function_failure_alarm = local.application_data.accounts[local.environment].alarms.lambda.postgres_tickle_function_failure.create
  enable_postgres_tickle_function_failure_alarm = local.application_data.accounts[local.environment].alarms.lambda.postgres_tickle_function_failure.enable
  thrld_postgres_tickle_function_failure_alarm  = local.application_data.accounts[local.environment].alarms.lambda.postgres_tickle_function_failure.threshold
  period_postgres_tickle_function_failure_alarm = local.application_data.accounts[local.environment].alarms.lambda.postgres_tickle_function_failure.period

  # CW Insights
  enable_cw_insights = local.application_data.accounts[local.environment].setup_cw_insights

  # Setup Athena Workgroups
  setup_dpr_generic_athena_workgroup       = local.application_data.accounts[local.environment].dpr_generic_athena_workgroup
  setup_analytics_generic_athena_workgroup = local.application_data.accounts[local.environment].analytics_generic_athena_workgroup

  # Sonatype Secrets
  setup_sonatype_secrets = local.application_data.accounts[local.environment].setup_sonatype_secrets

  # Nomis Secrets PlaceHolder
  nomis_secrets_placeholder = {
    db_name = "nomis"
    #checkov:skip=CKV_SECRET_6 This is a placeholder secret that is replaced with the real thing
    password = "placeholder"
    # We need to duplicate the username with 'user' and 'username' keys
    user     = "placeholder"
    username = "placeholder"
    endpoint = "0.0.0.0" # In dev this is always manually set to the static_private_ip of the ec2_bastion_host acting as a tunnel to NOMIS
    port     = "1521"
  }

  # Bodmis Secrets PlaceHolder
  bodmis_secrets_placeholder = {
    db_name  = "bodmis"
    password = "placeholder"
    user     = "placeholder"
    username = "placeholder"
    endpoint = "0.0.0.0" # In dev this is always manually set to the static_private_ip of the ec2_bastion_host acting as a tunnel to NOMIS
    port     = "1522"
  }

  # OASys Secrets PlaceHolder
  oasys_secrets_placeholder = {
    db_name  = "oasys"
    password = "placeholder"
    user     = "placeholder"
    username = "placeholder"
    endpoint = "0.0.0.0"
    port     = "0"
  }

  # ONR Secrets PlaceHolder
  onr_secrets_placeholder = {
    db_name  = "onr"
    password = "placeholder"
    user     = "placeholder"
    username = "placeholder"
    endpoint = "0.0.0.0"
    port     = "0"
  }

  # nDelius Secrets PlaceHolder
  ndelius_secrets_placeholder = {
    db_name  = "ndelius"
    password = "placeholder"
    user     = "placeholder"
    username = "placeholder"
    endpoint = "0.0.0.0"
    port     = "0"
  }

  # ndmis Secrets PlaceHolder
  ndmis_secrets_placeholder = {
    db_name  = "ndmis"
    password = "placeholder"
    user     = "placeholder"
    username = "placeholder"
    endpoint = "0.0.0.0"
    port     = "0"
  }

  # DPS Secrets PlaceHolder
  dps_domains_list = local.application_data.accounts[local.environment].dps_domains
  dps_secrets_placeholder = {
    db_name            = "dps"
    password           = "placeholder"
    user               = "placeholder"
    endpoint           = "0.0.0.0"
    port               = "5432"
    heartbeat_endpoint = "0.0.0.0"
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

  # Placeholder for unpopulated Operational DataStore access secrets
  ods_access_secret_placeholder = {
    host     = module.aurora_operational_db.cluster_endpoint
    port     = tostring(local.operational_db_port)
    database = local.operational_db_default_database
    username = "placeholder"
    password = "placeholder"
  }

  analytical_platform_share = can(local.application_data.accounts[local.environment].analytical_platform_share) ? { for share in local.application_data.accounts[local.environment].analytical_platform_share : share.target_account_name => share } : {}

  # Observability Platform & Analytical Platform
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      analytical_platform_runner_suffix = "-dev"
    }
    test = {
      analytical_platform_runner_suffix = "-test"
    }
    preproduction = {
      analytical_platform_runner_suffix = "-pp"
    }
    production = {
      analytical_platform_runner_suffix = ""
    }
  }


  all_tags = merge(
    local.tags,
    {
      dpr-name       = local.application_name
      dpr-jira       = "DPR-108"
      dpr-is-backend = true
    }
  )

  # DPR Operations,
  # S3 Data Migration Lambda
  enable_s3_data_migrate_lambda         = local.application_data.accounts[local.environment].enable_s3_data_migrate_lambda
  lambda_s3_data_migrate_name           = "${local.project}-s3-data-lifecycle-migration-lambda"
  lambda_s3_data_migrate_code_s3_bucket = module.s3_artifacts_store.bucket_id
  lambda_s3_data_migrate_code_s3_key    = "build-artifacts/dpr-operations/py_files/dpr-s3-data-lifecycle-migration-lambda-v2.zip"
  lambda_s3_data_migrate_handler        = "dpr-s3-data-lifecycle-migration-lambda-v2.lambda_handler"
  lambda_s3_data_migrate_runtime        = "python3.11"
  lambda_s3_data_migrate_tracing        = "PassThrough"
  lambda_s3_data_migrate_policies = [
    "arn:aws:iam::${local.account_id}:policy/${local.s3_read_access_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.s3_read_write_policy}"
  ]

  create_postgres_load_generator_job = local.application_data.accounts[local.environment].create_postgres_load_generator_job

  # Probation Discovery
  probation_discovery_windows_ami_id = "ami-03c8cd9ad2f2d6256"
  enable_probation_discovery_node    = local.application_data.accounts[local.environment].enable_probation_discovery_node

  dpr_windows_rdp_credentials_placeholder = {
    username = "placeholder"
    password = "placeholder"
  }
}
