# tflint-ignore-file: terraform_required_version, terraform_required_providers
# Maintenance Pipeline Step Function
module "maintenance_pipeline" {
  source = "../../step_function"

  enable_step_function = var.setup_maintenance_pipeline
  step_function_name   = var.maintenance_pipeline_name

  step_function_execution_role_arn = var.step_function_execution_role_arn

  definition = jsonencode(
    {
      "Comment" : "Maintenance Pipeline Step Function",
      "StartAt" : "Stop DMS Replication Task",
      "States" : {
        "Stop DMS Replication Task" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.stop_dms_task_job,
            "Arguments" : {
              "--dpr.dms.replication.task.id" : var.replication_task_id
            }
          },
          "Next" : "Check All Pending Files Have Been Processed"
        },
        "Check All Pending Files Have Been Processed" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_unprocessed_raw_files_check_job,
            "Arguments" : {
              "--dpr.orchestration.wait.interval.seconds" : tostring(var.processed_files_check_wait_interval_seconds),
              "--dpr.orchestration.max.attempts" : tostring(var.processed_files_check_max_attempts),
              "--dpr.datastorage.retry.maxAttempts" : tostring(var.glue_s3_max_attempts),
              "--dpr.datastorage.retry.minWaitMillis" : tostring(var.glue_s3_retry_min_wait_millis),
              "--dpr.datastorage.retry.maxWaitMillis" : tostring(var.glue_s3_retry_max_wait_millis)
            }
          },
          "Next" : "Stop Glue Streaming Job"
        },
        "Stop Glue Streaming Job" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_stop_glue_instance_job,
            "Arguments" : {
              "--dpr.stop.glue.instance.job.name" : var.glue_reporting_hub_cdc_jobname
            }
          },
          "Next" : "Run Compaction Job on Structured Zone"
        },
        "Run Compaction Job on Structured Zone" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_maintenance_compaction_job,
            "Arguments" : {
              "--dpr.maintenance.root.path" : var.s3_structured_path,
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            },
            "NumberOfWorkers" : var.compaction_structured_num_workers,
            "WorkerType" : var.compaction_structured_worker_type
          },
          "Next" : "Run Vacuum Job on Structured Zone"
        },
        "Run Vacuum Job on Structured Zone" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_maintenance_retention_job,
            "Arguments" : {
              "--dpr.maintenance.root.path" : var.s3_structured_path,
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            },
            "NumberOfWorkers" : var.retention_structured_num_workers,
            "WorkerType" : var.retention_structured_worker_type
          },
          "Next" : "Run Compaction Job on Curated Zone"
        },
        "Run Compaction Job on Curated Zone" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_maintenance_compaction_job,
            "Arguments" : {
              "--dpr.maintenance.root.path" : var.s3_curated_path,
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            },
            "NumberOfWorkers" : var.compaction_curated_num_workers,
            "WorkerType" : var.compaction_curated_worker_type
          },
          "Next" : "Run Vacuum Job on Curated Zone"
        },
        "Run Vacuum Job on Curated Zone" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_maintenance_retention_job,
            "Arguments" : {
              "--dpr.maintenance.root.path" : var.s3_curated_path,
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            },
            "NumberOfWorkers" : var.retention_curated_num_workers,
            "WorkerType" : var.retention_curated_worker_type
          },
          "Next" : "Archive Raw Data"
        },
        "Archive Raw Data" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_archive_job,
            "Arguments" : {
              "--dpr.raw.file.retention.period.amount" : "0"
            }
          },
          "Next" : "Resume DMS Replication Task"
        },
        "Resume DMS Replication Task" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::aws-sdk:databasemigration:startReplicationTask",
          "Parameters" : {
            "ReplicationTaskArn" : var.dms_replication_task_arn,
            "StartReplicationTaskType" : "resume-processing"
          },
          "Next" : "Start Glue Streaming Job"
        },
        "Start Glue Streaming Job" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun",
          "Parameters" : {
            "JobName" : var.glue_reporting_hub_cdc_jobname,
            "Arguments" : {
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            }
          },
          "End" : true
        }
      }
    }
  )

  tags = var.tags

}