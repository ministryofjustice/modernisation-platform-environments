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
      "StartAt" : "Deactivate Archive Trigger",
      "States" : {
        "Deactivate Archive Trigger" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_trigger_activation_job,
            "Arguments" : {
              "--dpr.glue.trigger.name" : var.archive_job_trigger_name,
              "--dpr.glue.trigger.activate" : "false"
            }
          },
          "Next" : "Stop Archive Job"
        },
        "Stop Archive Job" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_stop_glue_instance_job,
            "Arguments" : {
              "--dpr.stop.glue.instance.job.name" : var.glue_archive_job
            }
          },
          "Next" : "Stop DMS Replication Task"
        },
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
          "Resource" : "arn:aws:states:::glue:startJobRun",
          "Parameters" : {
            "JobName" : var.glue_unprocessed_raw_files_check_job,
            "Arguments" : {
              "--dpr.orchestration.wait.interval.seconds" : "60"
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
          "Next" : "Archive Remaining Raw Files"
        },
        "Archive Remaining Raw Files" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_file_transfer_job,
            "Arguments" : {
              "--dpr.file.transfer.source.bucket" : var.s3_raw_bucket_id,
              "--dpr.file.transfer.destination.bucket" : var.s3_raw_archive_bucket_id,
              "--dpr.file.transfer.delete.copied.files" : "true",
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Update Hive Tables"
        },
        "Update Hive Tables" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_hive_table_creation_jobname,
            "Arguments" : {
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Prepare Temp Reload Bucket Data"
        },
        "Prepare Temp Reload Bucket Data" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_data_deletion_job,
            "Arguments" : {
              "--dpr.file.deletion.buckets" : var.s3_temp_reload_bucket_id,
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Copy Curated Data to Temp-Reload Bucket"
        },
        "Copy Curated Data to Temp-Reload Bucket" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_file_transfer_job,
            "Arguments" : {
              "--dpr.file.transfer.source.bucket" : var.s3_curated_bucket_id,
              "--dpr.file.transfer.destination.bucket" : var.s3_temp_reload_bucket_id,
              "--dpr.file.transfer.retention.period.amount" : "0",
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
          "Next" : "Empty Raw, Structured and Curated Data"
        },
        "Empty Raw, Structured and Curated Data" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_data_deletion_job,
            "Arguments" : {
              "--dpr.file.deletion.buckets" : "${var.s3_raw_bucket_id},${var.s3_structured_bucket_id},${var.s3_curated_bucket_id}",
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
          "Next" : "Run Glue Batch Job"
        },
        "Run Glue Batch Job" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_reporting_hub_batch_jobname,
            "Arguments" : {
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Delete Existing Reload Diffs"
        },
        "Delete Existing Reload Diffs" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_data_deletion_job,
            "Arguments" : {
              "--dpr.file.deletion.buckets" : var.s3_temp_reload_bucket_id,
              "--dpr.file.source.prefix" : var.reload_diff_folder,
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Run Create Reload Diff Batch Job"
        },
        "Run Create Reload Diff Batch Job" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_create_reload_diff_job
          },
          "Next" : "Move Reload Diffs toInsert to Archive Bucket"
        },
        "Move Reload Diffs toInsert to Archive Bucket" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_file_transfer_job,
            "Arguments" : {
              "--dpr.file.transfer.source.bucket" : var.s3_temp_reload_bucket_id,
              "--dpr.file.source.prefix" : "${var.reload_diff_folder}/toInsert",
              "--dpr.file.transfer.destination.bucket" : var.s3_raw_archive_bucket_id,
              "--dpr.file.transfer.retention.period.amount" : "0",
              "--dpr.file.transfer.delete.copied.files" : "true",
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Move Reload Diffs toDelete to Archive Bucket"
        },
        "Move Reload Diffs toDelete to Archive Bucket" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_file_transfer_job,
            "Arguments" : {
              "--dpr.file.transfer.source.bucket" : var.s3_temp_reload_bucket_id,
              "--dpr.file.source.prefix" : "${var.reload_diff_folder}/toDelete",
              "--dpr.file.transfer.destination.bucket" : var.s3_raw_archive_bucket_id,
              "--dpr.file.transfer.retention.period.amount" : "0",
              "--dpr.file.transfer.delete.copied.files" : "true",
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Move Reload Diffs toUpdate to Archive Bucket"
        },
        "Move Reload Diffs toUpdate to Archive Bucket" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_file_transfer_job,
            "Arguments" : {
              "--dpr.file.transfer.source.bucket" : var.s3_temp_reload_bucket_id,
              "--dpr.file.source.prefix" : "${var.reload_diff_folder}/toUpdate",
              "--dpr.file.transfer.destination.bucket" : var.s3_raw_archive_bucket_id,
              "--dpr.file.transfer.retention.period.amount" : "0",
              "--dpr.file.transfer.delete.copied.files" : "true",
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Empty Raw Data"
        },
        "Empty Raw Data" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_data_deletion_job,
            "Arguments" : {
              "--dpr.file.deletion.buckets" : var.s3_raw_bucket_id,
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
          "Next" : "Reactivate Archive Trigger"
        },
        "Reactivate Archive Trigger" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_trigger_activation_job,
            "Arguments" : {
              "--dpr.glue.trigger.name" : var.archive_job_trigger_name,
              "--dpr.glue.trigger.activate" : "true"
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