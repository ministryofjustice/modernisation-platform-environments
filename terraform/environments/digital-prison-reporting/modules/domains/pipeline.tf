# Data Ingest Pipeline Step Function
module "data_ingestion_pipeline" {
  source = "./modules/step_function"

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
  #  module.s3_file_transfer_lambda.lambda_function,
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
            "ReplicationTaskArn" : var.dms_replication_task_arn, # DYNAMIC
            "StartReplicationTaskType" : "reload-target"
          },
          "Next" : "Invoke DMS State Control Lambda"
        },
        "Invoke DMS State Control Lambda" : {
          "Type" : "Task",
          "TimeoutSeconds" : local.dms_task_time_out,
          "Resource" : "arn:aws:states:::lambda:invoke.waitForTaskToken",
          "Parameters" : {
            "Payload" : {
              "token.$" : "$$.Task.Token",
              "replicationTaskArn" : var.dms_replication_task_arn # DYNAMIC
            },
            "FunctionName" : var.pipeline_notification_lambda_function # DYNAMIC
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
            "JobName" : var.glue_reporting_hub_batch_jobname # DYNAMIC
          },
          "Next" : "Invoke S3 File Transfer Lambda"
        },
        "Invoke S3 File Transfer Lambda" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::lambda:invoke.waitForTaskToken",
          "Parameters" : {
            "Payload" : {
              "token.$" : "$$.Task.Token",
              "sourceBucket" : var.s3_raw_bucket_id, # DYNAMIC
              "destinationBucket" : var.s3_raw_archive_bucket_id # NEW PARAM, WIP
            },
            "FunctionName" : var.s3_file_transfer_lambda_function
          },
          "Retry" : [
            {
              "ErrorEquals" : [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException"
              ],
              "IntervalSeconds" : 600,
              "MaxAttempts" : 2,
              "BackoffRate" : 2
            }
          ],
          "Next" : "Create Hive Tables"
        },
        "Create Hive Tables" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_hive_table_creation_jobname  # DYNAMIC # NEW PARAM, WIP
          },
          "Next" : "Resume DMS Replication Task"
        },
        "Resume DMS Replication Task" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::aws-sdk:databasemigration:startReplicationTask",
          "Parameters" : { 
            "ReplicationTaskArn" : var.dms_replication_task_arn,   # DYNAMIC
            "StartReplicationTaskType" : "resume-processing"
          },
          "Next" : "Start Glue Streaming Job"
        },
        "Start Glue Streaming Job" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun",
          "Parameters" : {
            "JobName" : var.glue_reporting_hub_cdc_jobname    # DYNAMIC
          },
          "End" : true
        }
      }
    }
  )


}