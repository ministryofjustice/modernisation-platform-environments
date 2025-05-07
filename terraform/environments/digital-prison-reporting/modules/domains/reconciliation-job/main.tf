# tflint-ignore-file: terraform_required_version, terraform_required_providers
# Data Reconciliation Job
module "glue_s3_data_reconciliation_job" {
  source                        = "../../glue_job"
  create_job                    = var.create_job
  create_role                   = var.create_role
  name                          = var.job_name
  short_name                    = var.short_name
  command_type                  = "glueetl"
  description                   = "Reconciles data across DataHub.\nArguments:\n--dpr.config.key: (Required) config key e.g. prisoner\n--dpr.dms.replication.task.id: (Required) ID of the DMS replication task to reconcile against the raw zone\n--dpr.reconciliation.checks.to.run: (Optional) Allows restricting the set of checks that will be run"
  create_security_configuration = var.create_sec_conf
  job_language                  = "scala"
  # Placeholder Script Location
  script_location              = "s3://${var.project_id}-artifact-store-${var.env}/build-artifacts/digital-prison-reporting-jobs/scripts/${var.script_file_version}"
  temp_dir                     = var.temp_dir
  enable_continuous_log_filter = var.enable_continuous_log_filter
  project_id                   = var.project_id
  aws_kms_key                  = var.s3_kms_arn
  spark_event_logs             = var.spark_event_logs

  execution_class             = var.execution_class
  worker_type                 = var.worker_type
  number_of_workers           = var.num_workers
  max_concurrent              = var.max_concurrent_runs
  region                      = var.account_region
  account                     = var.account_id
  log_group_retention_in_days = var.log_group_retention_in_days
  connections                 = var.connections
  additional_secret_arns      = var.additional_secret_arns
  enable_spark_ui             = var.enable_spark_ui

  tags = merge(
    var.tags,
    {
      Resource_Type = "Glue Job"
    }
  )

  arguments = var.glue_job_arguments
}

resource "aws_glue_trigger" "glue_file_archive_job_trigger" {
  count    = var.create_job && var.job_schedule != "" ? 1 : 0
  name     = "${module.glue_s3_data_reconciliation_job.name}-trigger"
  schedule = var.job_schedule
  type     = "SCHEDULED"

  actions {
    job_name = module.glue_s3_data_reconciliation_job.name
  }

  tags = {
    Name          = "${module.glue_s3_data_reconciliation_job.name}-trigger"
    Resource_Type = "Glue Trigger"
    Jira          = "DPR2-1135"
  }
}