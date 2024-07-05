# Data Ingest Pipeline Step Function
module "data_ingestion_pipeline" {
  source = "../../step_function"

  enable_step_function = var.setup_data_ingestion_pipeline
  step_function_name   = var.data_ingestion_pipeline
  dms_task_time_out    = var.pipeline_dms_task_time_out

  additional_policies = var.pipeline_additional_policies

  # Send this block to the calling repo Pipeline
  #depends_on = [
  #  aws_iam_policy.invoke_lambda_policy,
  #  aws_iam_policy.start_dms_task_policy,
  #  aws_iam_policy.trigger_glue_job_policy,
  #  module.dms_nomis_to_s3_ingestor.dms_replication_task_arn,
  #  module.glue_reporting_hub_batch_job.name,
  #  module.glue_reporting_hub_cdc_job.name,
  #  module.glue_hive_table_creation_job.name,
  #  module.step_function_notification_lambda.lambda_function
  #]

  definition = jsonencode(
    {
      "Comment" : "Data Ingestion Pipeline Step Function",
      "StartAt" : "Start DMS Replication Task",
      "States" : {
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
              "--dpr.file.transfer.retention.period.amount" : "0",
              "--dpr.file.transfer.delete.copied.files" : "true",
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
              "--dpr.allowed.s3.file.extensions" : ".parquet",
              "--dpr.config.key" : var.domain
            }
          },
          "Next" : "Create Hive Tables"
        },
        "Create Hive Tables" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_hive_table_creation_jobname,
            "Arguments" : {
              "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
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
          "End" : true
        }
      }
    }
  )

  tags = var.tags

}