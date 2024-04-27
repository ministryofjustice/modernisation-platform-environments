# Replay Pipeline Step Function
module "replay_pipeline" {
  source = "../../step_function"

  enable_step_function = var.setup_replay_pipeline
  step_function_name   = var.replay_pipeline

  additional_policies = var.pipeline_additional_policies

  definition = jsonencode(
    {
      "Comment" : "Replay Pipeline Step Function",
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
              "--dpr.file.deletion.buckets" : "${var.s3_structured_bucket_id},${var.s3_curated_bucket_id}",
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Move Processed Data Back to Raw Bucket"
        },
        "Move Processed Data Back to Raw Bucket" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_file_transfer_job,
            "Arguments" : {
              "--dpr.file.transfer.source.bucket" : var.s3_raw_bucket_id,
              "--dpr.file.source.prefix" : "processed",
              "--dpr.file.transfer.destination.bucket" : var.s3_raw_bucket_id,
              "--dpr.file.transfer.retention.days" : "0",
              "--dpr.file.transfer.delete.copied.files" : "true",
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Move Archived Data Back to Raw Bucket"
        },
        "Move Archived Data Back to Raw Bucket" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_s3_file_transfer_job,
            "Arguments" : {
              "--dpr.file.transfer.source.bucket" : var.s3_raw_archive_bucket_id,
              "--dpr.file.transfer.destination.bucket" : var.s3_raw_bucket_id,
              "--dpr.file.transfer.retention.days" : "0",
              "--dpr.file.transfer.delete.copied.files" : "true",
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.config.key" : var.domain
            }
          },
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
          "Next" : "Start Glue Streaming Job"
        },
        "Start Glue Streaming Job" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun",
          "Parameters" : {
            "JobName" : var.glue_reporting_hub_cdc_jobname,
            "Arguments" : {
              "--dpr.clean.cdc.checkpoint" : "true",
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
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