# ------------------------------------------
# Unzip Files
# ------------------------------------------

module "get_zipped_file_api" {
  source       = "./modules/step_function"
  name         = "get_zipped_file_api"
  iam_policies = tomap({ "trigger_unzip_lambda" = aws_iam_policy.trigger_unzip_lambda })
  variable_dictionary = tomap(
    {
      "unzip_file_name"            = module.unzip_single_file.lambda_function_name,
      "pre_signed_url_lambda_name" = module.unzipped_presigned_url.lambda_function_name
    }
  )
  type = "EXPRESS"
}

# ------------------------------------------
# DMS Validation Step Function
# ------------------------------------------

module "dms_validation_step_function" {
  count = local.is-development || local.is-production || local.is-preproduction ? 1 : 0

  source       = "./modules/step_function"
  name         = "dms_validation"
  iam_policies = tomap({ "dms_validation_step_function_policy" = aws_iam_policy.dms_validation_step_function_policy[0] })
  variable_dictionary = tomap(
    {
      "dms_retrieve_metadata" = module.dms_retrieve_metadata[0].lambda_function_name,
      "dms_validation"        = module.dms_validation[0].lambda_function_name,
    }
  )
  type = "STANDARD"
}


# ------------------------------------------
# Data Cut Back Step Function
# ------------------------------------------

module "data_cutback_step_function" {
  count = local.is-development || local.is-production ? 1 : 0

  source       = "./modules/step_function"
  name         = "data_cutback"
  iam_policies = tomap({ "data_cutback_step_function_policy" = aws_iam_policy.data_cutback_step_function_policy[0] })
  variable_dictionary = tomap(
    {
      "data_cutback" = module.data_cutback[0].lambda_function_name,
    }
  )
  type = "STANDARD"
}


# ------------------------------------------
# Ears and Sars Step funtion
# ------------------------------------------

module "ears_sars_step_function" {
  count = local.is-development || local.is-preproduction || local.is-production ? 1 : 0

  source       = "./modules/step_function"
  name         = "ears_sars"
  iam_policies = tomap({ "ears_sars_step_function_policy" = aws_iam_policy.ears_sars_step_function_policy[0] })
  variable_dictionary = tomap(
    {
      "ears_sars_request"   = module.ears_sars_request[0].lambda_function_name,
      "write_to_sharepoint" = module.write_to_sharepoint[0].lambda_function_name,
    }
  )
  type = "STANDARD"
}


# ------------------------------------------
# GDPR Step Function
# ------------------------------------------

module "gdpr_deletion_step_function" {
  count        = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  source       = "./modules/step_function"
  name         = "gdpr_deletion"
  iam_policies = tomap({ "gdpr_deletion_step_function_policy" = aws_iam_policy.gdpr_delete_iam_policy[0] })
  variable_dictionary = tomap(
    {
      "cluster_arn"              = aws_ecs_cluster.emds-gdpr-cluster[0].arn
      "task_definition_family"   = aws_ecs_task_definition.emds-gdpr-structured-data-deletion[0].family
      "container_name"           = "emds_gdpr_structured_data_deletion_job"
      "security_groups_json"     = jsonencode([aws_security_group.ecs_generic.id])
      "subnets_json"             = jsonencode(data.aws_subnets.shared-private.ids)
      "athena_output_bucket"     = "s3://${module.s3-athena-bucket.bucket.id}/output/"
      "control_lambda_arn"       = module.gdpr_unstructured_control_lambda[0].lambda_function_arn
      "batch_job_queue_arn"      = aws_batch_job_queue.shred_unstructured_from_zip_batch_queue[0].arn
      "batch_job_definition_arn" = aws_batch_job_definition.shred_unstructured_from_zip_job.arn
      "sns_topic_arn"            = aws_sns_topic.emds_alerts.arn
      "environment_name"         = local.environment_shorthand
    }
  )
  type = "STANDARD"
}


# ------------------------------------------
# Iceberg Step Function
# ------------------------------------------


module "iceberg_table_maintenance_step_function" {
  count        = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  source       = "./modules/step_function"
  name         = "iceberg_table_maintenance"
  iam_policies = tomap({ "gdpr_deletion_step_function_policy" = aws_iam_policy.gdpr_delete_iam_policy[0] })
  variable_dictionary = tomap(
    {
      "cluster_arn"            = aws_ecs_cluster.emds-gdpr-cluster[0].arn
      "task_definition_family" = aws_ecs_task_definition.emds-gdpr-iceberg-table-maintenance[0].family
      "container_name"         = "emds_gdpr_iceberg_table_maintenance_job"
      "security_groups_json"   = jsonencode([aws_security_group.ecs_generic.id])
      "subnets_json"           = jsonencode(data.aws_subnets.shared-private.ids)
      "athena_output_bucket"   = "s3://${module.s3-athena-bucket.bucket.id}/output/"
    }
  )
  type = "STANDARD"
}

# ------------------------------------------
# Insert into emdi position step function
# ------------------------------------------

module "insert_into_mdss_staged_position" {
  source       = "./modules/merge_into_reconciler"
  function_to_iterate = module.merge_mdss_staged_position[0]
}

# ------------------------------------------
# Insert into emdi position step function
# ------------------------------------------

module "insert_into_emdi_position" {
  source       = "./modules/merge_into_reconciler"
  function_to_iterate = module.merge_emdi_position[0]
}

# ------------------------------------------------------------------------------
# Staging DB janitor Step Function
# ------------------------------------------------------------------------------

resource "aws_sfn_state_machine" "staging_db_janitor" {
  name     = "staging_db_janitor"
  role_arn = aws_iam_role.staging_db_janitor_state_machine.arn

  definition = jsonencode(
    {
      Comment = "Orchestrates stale staging database cleanup in batches."
      StartAt = "JanitorBatch"
      States = {
        JanitorBatch = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.staging_db_janitor.lambda_function_arn
            Payload = {
              "thread_id.$"             = "$.thread_id"
              "alarm_name.$"            = "$.alarm_name"
              "batch_number.$"          = "$.batch_number"
              "stale_minutes.$"         = "$.stale_minutes"
              "max_databases_per_run.$" = "$.max_databases_per_run"
            }
          }
          OutputPath = "$.Payload"
          Retry = [
            {
              ErrorEquals = [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException"
              ]
              IntervalSeconds = 2
              BackoffRate     = 2
              MaxAttempts     = 3
            }
          ]
          Next = "CheckStatus"
        }

        CheckStatus = {
          Type = "Choice"
          Choices = [
            {
              Variable     = "$.status"
              StringEquals = "continuing"
              Next         = "WaitBeforeNextBatch"
            },
            {
              Variable     = "$.status"
              StringEquals = "ok"
              Next         = "Complete"
            },
            {
              Variable     = "$.status"
              StringEquals = "halted"
              Next         = "Halted"
            }
          ]
          Default = "UnexpectedResult"
        }

        WaitBeforeNextBatch = {
          Type    = "Wait"
          Seconds = 15
          Next    = "PrepareNextBatch"
        }

        PrepareNextBatch = {
          Type = "Pass"
          Parameters = {
            "thread_id.$"             = "$.thread_id"
            "alarm_name.$"            = "$.alarm_name"
            "batch_number.$"          = "$.next_batch_number"
            "stale_minutes.$"         = "$.stale_minutes"
            "max_databases_per_run.$" = "$.max_databases_per_run"
          }
          Next = "JanitorBatch"
        }

        Complete = {
          Type = "Succeed"
        }

        Halted = {
          Type  = "Fail"
          Error = "StagingDbCleanupHalted"
          Cause = "The janitor made no progress and stopped safely."
        }

        UnexpectedResult = {
          Type  = "Fail"
          Error = "UnexpectedJanitorResult"
          Cause = "The janitor returned an unexpected status."
        }
      }
    }
  )
}

# ------------------------------------------------------------------------------
# Landing DLQ redriver Step Function
# ------------------------------------------------------------------------------

resource "aws_sfn_state_machine" "landing_dlq_redriver" {
  name     = "landing_dlq_redriver"
  role_arn = aws_iam_role.landing_dlq_redriver_state_machine.arn

  definition = jsonencode({
    Comment = "Redrives landing DLQ messages after CloudWatch DLQ alarms."
    StartAt = "WaitForThreadState"
    States = {
      WaitForThreadState = {
        Type    = "Wait"
        Seconds = 600
        Next    = "RedriverBatch"
      }

      RedriverBatch = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.landing_file_dlq_redriver.lambda_function_arn
          "Payload.$"  = "$"
        }
        OutputPath = "$.Payload"
        Retry = [
          {
            ErrorEquals = [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "Lambda.TooManyRequestsException",
            ]
            IntervalSeconds = 2
            BackoffRate     = 2
            MaxAttempts     = 3
          }
        ]
        Next = "CheckStatus"
      }

      CheckStatus = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.status"
            StringEquals = "continuing"
            Next         = "WaitBeforeNextBatch"
          },
          {
            Variable     = "$.status"
            StringEquals = "settling"
            Next         = "WaitAfterReplay"
          },
          {
            Variable     = "$.status"
            StringEquals = "ok"
            Next         = "Complete"
          },
          {
            Variable     = "$.status"
            StringEquals = "completed_with_manual_items"
            Next         = "Complete"
          },
          {
            Variable     = "$.status"
            StringEquals = "completed_with_retry_limit_items"
            Next         = "Complete"
          },
          {
            Variable = "$.status"
            StringEquals = join("", [
              "completed_with_manual_and_retry_",
              "limit_items",
            ])
            Next = "Complete"
          },
          {
            Variable     = "$.status"
            StringEquals = "completed_with_invalid_items"
            Next         = "Complete"
          },
          {
            Variable     = "$.status"
            StringEquals = "halted_at_batch_limit"
            Next         = "Complete"
          },
          {
            Variable     = "$.status"
            StringEquals = "halted"
            Next         = "Complete"
          },
          {
            Variable     = "$.status"
            StringEquals = "ignored"
            Next         = "Complete"
          }
        ]
        Default = "UnexpectedResult"
      }

      WaitBeforeNextBatch = {
        Type    = "Wait"
        Seconds = 30
        Next    = "RedriverBatch"
      }

      WaitAfterReplay = {
        Type    = "Wait"
        Seconds = 300
        Next    = "RedriverBatch"
      }

      Complete = {
        Type = "Succeed"
      }

      UnexpectedResult = {
        Type  = "Fail"
        Error = "UnexpectedLandingRedriverResult"
        Cause = "The landing redriver returned an unexpected status."
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "landing_dlq_redriver" {
  rule     = aws_cloudwatch_event_rule.alarm_state_change_threader.name
  arn      = aws_sfn_state_machine.landing_dlq_redriver.arn
  role_arn = aws_iam_role.landing_dlq_redriver_eventbridge.arn
}
