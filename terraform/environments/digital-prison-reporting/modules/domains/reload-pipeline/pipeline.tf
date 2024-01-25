# Reload Pipeline Step Function
module "reload_pipeline" {
  source = "../../step_function"

  enable_step_function = var.setup_reload_pipeline
  step_function_name   = var.reload_pipeline
  dms_task_time_out    = var.pipeline_dms_task_time_out

  additional_policies = var.pipeline_additional_policies

  definition = jsonencode(
    {
      "Comment" : "Reload Pipeline Step Function",
      "StartAt" : "Stop Glue Streaming Job",
      "States" : {
        "Stop Glue Streaming Job" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_stop_glue_instance_job,
            "Arguments" : {
              "--dpr.stop.glue.instance.job.name" : var.glue_reporting_hub_cdc_jobname
            }
          },
          "Next" : "Copy Data to Temp-Reload Bucket"
        },
        "Copy Data to Temp-Reload Bucket" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_file_transfer_job,
            "Arguments" : {
              "--dpr.file.transfer.source.bucket" : var.s3_curated_bucket_id,
              "--dpr.file.transfer.destination.bucket" : var.s3_temp_reload_bucket_id,
              "--dpr.file.transfer.retention.days" : "0",
              "--dpr.file.transfer.delete.copied.files" : "false",
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Switch Hive Tables for Prisons to Temp-Reload Bucket"
        },
        "Switch Hive Tables for Prisons to Temp-Reload Bucket" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_switch_prisons_hive_data_location_job,
            "Arguments" : {
              "--dpr.prisons.data.switch.target.s3.path" : "s3://${var.s3_temp_reload_bucket_id}",
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Truncate Data"
        },
        "Truncate Data" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_data_deletion_job,
            "Arguments" : {
              "--dpr.file.deletion.buckets" : "${var.s3_raw_bucket_id},${var.s3_raw_archive_bucket_id},${var.s3_structured_bucket_id},${var.s3_curated_bucket_id}",
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Start DMS Replication Task"
        },
        "Start DMS Replication Task" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::aws-sdk:databasemigration:startReplicationTask",
          "Parameters" : {
            "ReplicationTaskArn" : var.dms_replication_task_arn,
            "StartReplicationTaskType" : "reload-target"
          },
          "Next" : "Invoke DMS State Control Lambda"
        },
        "Invoke DMS State Control Lambda" : {
          "Type" : "Task",
          "TimeoutSeconds" : var.pipeline_dms_task_time_out,
          "Resource" : "arn:aws:states:::lambda:invoke.waitForTaskToken",
          "Parameters" : {
            "Payload" : {
              "token.$" : "$$.Task.Token",
              "replicationTaskArn" : var.dms_replication_task_arn
            },
            "FunctionName" : var.pipeline_notification_lambda_function
          },
          "Retry" : [
            {
              "ErrorEquals" : [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException"
              ],
              "IntervalSeconds" : 60,
              "MaxAttempts" : 2,
              "BackoffRate" : 2
            }
          ],
          "Next" : "Start Glue Batch Job"
        },
        "Start Glue Batch Job" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_reporting_hub_batch_jobname,
            "Arguments" : {
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Archive Raw Data"
        },
        "Archive Raw Data" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_file_transfer_job,
            "Arguments" : {
              "--dpr.file.transfer.source.bucket" : var.s3_raw_bucket_id,
              "--dpr.file.transfer.destination.bucket" : var.s3_raw_archive_bucket_id,
              "--dpr.file.transfer.retention.days" : "0",
              "--dpr.file.transfer.delete.copied.files" : "true",
              "--dpr.allowed.s3.file.extensions" : ".parquet",
              "--dpr.config.key" : var.domain
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
          "Next" : "Switch Hive Tables for Prisons to Curated"
        },
        "Switch Hive Tables for Prisons to Curated" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_switch_prisons_hive_data_location_job,
            "Arguments" : {
              "--dpr.prisons.data.switch.target.s3.path" : "s3://${var.s3_curated_bucket_id}",
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Empty Temp Reload Bucket Data"
        },
        "Empty Temp Reload Bucket Data" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_data_deletion_job,
            "Arguments" : {
              "--dpr.file.deletion.buckets" : var.s3_temp_reload_bucket_id,
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