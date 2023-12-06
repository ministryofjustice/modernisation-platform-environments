# Lambda which notifies step function when DMS task stops
module "step_function_notification_lambda" {
  source = "./modules/lambdas/generic"

  enable_lambda = local.enable_step_function_notification_lambda
  name          = local.step_function_notification_lambda_name
  s3_bucket     = local.s3_file_transfer_lambda_code_s3_bucket
  s3_key        = local.reporting_lambda_code_s3_key
  handler       = local.step_function_notification_lambda_handler
  runtime       = local.step_function_notification_lambda_runtime
  policies      = local.step_function_notification_lambda_policies
  tracing       = local.step_function_notification_lambda_tracing
  timeout       = 300 # 5 minutes

  vpc_settings = {
    subnet_ids = [
      data.aws_subnet.data_subnets_a.id,
      data.aws_subnet.data_subnets_b.id,
      data.aws_subnet.data_subnets_c.id
    ]

    security_group_ids = [
      aws_security_group.lambda_generic[0].id
    ]
  }

  tags = merge(
    local.all_tags,
    {
      Resource_Group = "ingestion-pipeline"
      Jira           = "DPR2-209"
      Resource_Type  = "Lambda"
      Name           = local.step_function_notification_lambda_name
    }
  )

  depends_on = [
    aws_iam_policy.kms_read_access_policy,
    aws_iam_policy.dynamodb_access_policy,
    aws_iam_policy.all_state_machine_policy
  ]
}

module "step_function_notification_lambda_trigger" {
  source = "./modules/lambda_trigger"

  enable_lambda_trigger = local.enable_step_function_notification_lambda

  event_name           = "${local.project}-step-function-notification-${local.env}"
  lambda_function_arn  = module.step_function_notification_lambda.lambda_function
  lambda_function_name = module.step_function_notification_lambda.lambda_name

  trigger_event_pattern = jsonencode(
    {
      "source" : ["aws.dms"],
      "detail-type" : ["DMS Replication Task State Change"],
      "detail" : {
        "eventId" : ["DMS-EVENT-0079"]
      }
    }
  )

  depends_on = [
    module.step_function_notification_lambda
  ]
}

# Data Ingest Pipeline Step Function
module "data_ingestion_pipeline" {
  source = "./modules/step_function"

  enable_step_function = local.enable_data_ingestion_step_function
  step_function_name   = local.data_ingestion_step_function_name
  dms_task_time_out    = local.dms_task_time_out

  additional_policies = [
    "arn:aws:iam::${local.account_id}:policy/${aws_iam_policy.invoke_lambda_policy.name}",
    "arn:aws:iam::${local.account_id}:policy/${aws_iam_policy.start_dms_task_policy.name}",
    "arn:aws:iam::${local.account_id}:policy/${aws_iam_policy.trigger_glue_job_policy.name}"
  ]

  depends_on = [
    aws_iam_policy.invoke_lambda_policy,
    aws_iam_policy.start_dms_task_policy,
    aws_iam_policy.trigger_glue_job_policy,
    module.dms_nomis_to_s3_ingestor.dms_replication_task_arn,
    module.glue_reporting_hub_batch_job.name,
    module.glue_reporting_hub_cdc_job.name,
    module.glue_hive_table_creation_job.name,
    module.s3_file_transfer_lambda.lambda_function,
    module.step_function_notification_lambda.lambda_function
  ]

  definition = jsonencode(
    {
      "Comment" : "Data Ingestion Pipeline Step Function",
      "StartAt" : "Start DMS Replication Task",
      "States" : {
        "Start DMS Replication Task" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::aws-sdk:databasemigration:startReplicationTask",
          "Parameters" : {
            "ReplicationTaskArn" : "${module.dms_nomis_to_s3_ingestor.dms_replication_task_arn}",
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
              "replicationTaskArn" : "${module.dms_nomis_to_s3_ingestor.dms_replication_task_arn}"
            },
            "FunctionName" : "${module.step_function_notification_lambda.lambda_function}"
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
            "JobName" : "${module.glue_reporting_hub_batch_job.name}"
          },
          "Next" : "Invoke S3 File Transfer Lambda"
        },
        "Invoke S3 File Transfer Lambda" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::lambda:invoke.waitForTaskToken",
          "Parameters" : {
            "Payload" : {
              "token.$" : "$$.Task.Token",
              "sourceBucket" : "${module.s3_raw_bucket.bucket_id}",
              "destinationBucket" : "${module.s3_raw_archive_bucket.bucket_id}"
            },
            "FunctionName" : "${module.s3_file_transfer_lambda.lambda_function}"
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
            "JobName" : "${module.glue_hive_table_creation_job.name}"
          },
          "Next" : "Resume DMS Replication Task"
        },
        "Resume DMS Replication Task" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::aws-sdk:databasemigration:startReplicationTask",
          "Parameters" : {
            "ReplicationTaskArn" : "${module.dms_nomis_to_s3_ingestor.dms_replication_task_arn}",
            "StartReplicationTaskType" : "resume-processing"
          },
          "Next" : "Start Glue Streaming Job"
        },
        "Start Glue Streaming Job" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun",
          "Parameters" : {
            "JobName" : "${module.glue_reporting_hub_cdc_job.name}"
          },
          "End" : true
        }
      }
    }
  )


}