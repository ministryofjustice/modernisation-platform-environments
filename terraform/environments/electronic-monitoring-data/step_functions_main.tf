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
# Merge into staged position step function
# ------------------------------------------

module "merge_into_mdss_staged_position" {
  source       = "./modules/merge_into_reconciler"
  function_to_iterate = module.merge_mdss_staged_position[0]
}

# ------------------------------------------
# Merge into staged event step function
# ------------------------------------------

module "merge_into_mdss_staged_event" {
  source       = "./modules/merge_into_reconciler"
  function_to_iterate = module.merge_mdss_staged_event[0]
}

# ------------------------------------------
# Merge into emdi position step function
# ------------------------------------------

module "merge_into_emdi_position" {
  source       = "./modules/merge_into_reconciler"
  function_to_iterate = module.merge_emdi_position[0]
}

# ------------------------------------------
# Merge into ac position step function
# ------------------------------------------

module "merge_into_mdss_ac_position" {
  source       = "./modules/merge_into_reconciler"
  function_to_iterate = module.merge_ac_position[0]
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

# ------------------------------------------------------------------------------
# Downstream position reconciliation Step Function
# ------------------------------------------------------------------------------

resource "aws_sfn_state_machine" "downstream_reconciliation" {
  name     = "downstream_position_reconciliation"
  role_arn = aws_iam_role.downstream_reconciliation_state_machine.arn

  definition = jsonencode(
    {
      Comment = "Plans, approves, replays and verifies AC and EMDI position reconciliation."
      StartAt = "SelectInputMode"
      States = {
        SelectInputMode = {
          Type = "Choice"
          Choices = [
            {
              Variable     = "$.mode"
              StringEquals = "rolling"
              Next         = "StartRollingReconciliation"
            },
            {
              Variable     = "$.mode"
              StringEquals = "historical"
              Next         = "StartRangedReconciliation"
            },
            {
              Variable     = "$.mode"
              StringEquals = "verify"
              Next         = "StartRangedReconciliation"
            },
          ]
          Default = "UnsupportedMode"
        }

        StartRollingReconciliation = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action        = "start"
              "consumer.$" = "$.consumer"
              "mode.$"     = "$.mode"
            }
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
          Next = "DiscoverRolling"
        }

        StartRangedReconciliation = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action                    = "start"
              "consumer.$"             = "$.consumer"
              "mode.$"                 = "$.mode"
              "requested_range.$"      = "$.requested_range"
            }
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
          Next = "PrepareHistoricalPlan"
        }

        DiscoverRolling = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action        = "discover_rolling"
              "consumer.$" = "$.consumer"
              "mode.$"     = "$.mode"
            }
          }
          ResultSelector = {
            "result.$" = "$.Payload"
          }
          ResultPath = "$.discovery"
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
          Next = "PrepareRollingPlan"
        }

        PrepareRollingPlan = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action           = "prepare_plan"
              "consumer.$"    = "$.consumer"
              "mode.$"        = "$.mode"
              "execution_id.$" = "$.execution_id"
              "dates.$"       = "$.discovery.result.dates"
            }
          }
          ResultSelector = {
            "result.$" = "$.Payload"
          }
          ResultPath = "$.planning"
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
          Next = "CheckPreparedPlan"
        }

        PrepareHistoricalPlan = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action                    = "prepare_plan"
              "consumer.$"             = "$.consumer"
              "mode.$"                 = "$.mode"
              "execution_id.$"         = "$.execution_id"
              "requested_range.$"      = "$.requested_range"
            }
          }
          ResultSelector = {
            "result.$" = "$.Payload"
          }
          ResultPath = "$.planning"
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
          Next = "CheckPreparedPlan"
        }

        CheckPreparedPlan = {
          Type = "Choice"
          Choices = [
            {
              Variable     = "$.planning.result.status"
              StringEquals = "nothing_to_do"
              Next         = "CompleteExecution"
            },
            {
              Variable     = "$.planning.result.status"
              StringEquals = "planning"
              Next         = "PlanNextScope"
            },
          ]
          Default = "UnexpectedPlanningResult"
        }

        PlanNextScope = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action            = "plan_next"
              "consumer.$"     = "$.consumer"
              "mode.$"         = "$.mode"
              "execution_id.$" = "$.execution_id"
            }
          }
          ResultSelector = {
            "result.$" = "$.Payload"
          }
          ResultPath = "$.plan_step"
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
          Next = "CheckPlanningStatus"
        }

        CheckPlanningStatus = {
          Type = "Choice"
          Choices = [
            {
              Variable     = "$.plan_step.result.status"
              StringEquals = "planning"
              Next         = "WaitBeforePlanningNextScope"
            },
            {
              Variable     = "$.plan_step.result.status"
              StringEquals = "nothing_to_do"
              Next         = "CompleteExecution"
            },
            {
              Variable     = "$.plan_step.result.status"
              StringEquals = "plan_ready"
              Next         = "CheckVerifyOnly"
            },
          ]
          Default = "UnexpectedPlanningResult"
        }

        WaitBeforePlanningNextScope = {
          Type    = "Wait"
          Seconds = 1
          Next    = "PlanNextScope"
        }

        CheckVerifyOnly = {
          Type = "Choice"
          Choices = [
            {
              Variable     = "$.mode"
              StringEquals = "verify"
              Next         = "CompleteExecution"
            },
          ]
          Default = "CheckApprovalRequired"
        }

        CheckApprovalRequired = {
          Type = "Choice"
          Choices = [
            {
              Variable      = "$.plan_step.result.approval_required"
              BooleanEquals = true
              Next          = "WaitForApproval"
            },
          ]
          Default = "SaveAutomaticApproval"
        }

        SaveAutomaticApproval = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action            = "save_plan"
              "consumer.$"     = "$.consumer"
              "mode.$"         = "$.mode"
              "execution_id.$" = "$.execution_id"
            }
          }
          ResultSelector = {
            "result.$" = "$.Payload"
          }
          ResultPath = "$.approval_state"
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
          Next = "NextReplayChunk"
        }

        WaitForApproval = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke.waitForTaskToken"
          TimeoutSeconds = 86400
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action            = "save_plan"
              "consumer.$"     = "$.consumer"
              "mode.$"         = "$.mode"
              "execution_id.$" = "$.execution_id"
              "task_token.$"   = "$$.Task.Token"
            }
          }
          ResultPath = "$.approval"
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
          Catch = [
            {
              ErrorEquals = ["States.Timeout"]
              ResultPath  = "$.approval_error"
              Next        = "ExpireApproval"
            }
          ]
          Next = "RecordApprovalDecision"
        }

        RecordApprovalDecision = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action            = "record_approval"
              "consumer.$"     = "$.consumer"
              "mode.$"         = "$.mode"
              "execution_id.$" = "$.execution_id"
              "decision.$"     = "$.approval.decision"
            }
          }
          ResultSelector = {
            "result.$" = "$.Payload"
          }
          ResultPath = "$.approval_state"
          Next       = "CheckApprovalDecision"
        }

        CheckApprovalDecision = {
          Type = "Choice"
          Choices = [
            {
              Variable     = "$.approval.decision"
              StringEquals = "approved"
              Next         = "NextReplayChunk"
            },
            {
              Variable     = "$.approval.decision"
              StringEquals = "rejected"
              Next         = "Rejected"
            },
          ]
          Default = "UnexpectedApprovalDecision"
        }

        ExpireApproval = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action            = "expire_approval"
              "consumer.$"     = "$.consumer"
              "mode.$"         = "$.mode"
              "execution_id.$" = "$.execution_id"
            }
          }
          OutputPath = "$.Payload"
          Next       = "ApprovalExpired"
        }

        NextReplayChunk = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action            = "next_chunk"
              "consumer.$"     = "$.consumer"
              "mode.$"         = "$.mode"
              "execution_id.$" = "$.execution_id"
            }
          }
          ResultSelector = {
            "result.$" = "$.Payload"
          }
          ResultPath = "$.chunk"
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
          Next = "CheckReplayStatus"
        }

        CheckReplayStatus = {
          Type = "Choice"
          Choices = [
            {
              Variable     = "$.chunk.result.status"
              StringEquals = "complete"
              Next         = "CompleteExecution"
            },
            {
              Variable     = "$.chunk.result.status"
              StringEquals = "chunk_ready"
              Next         = "RecheckReplayChunk"
            },
          ]
          Default = "UnexpectedReplayResult"
        }

        RecheckReplayChunk = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action            = "inspect_scope"
              "consumer.$"     = "$.consumer"
              "mode.$"         = "$.mode"
              "execution_id.$" = "$.execution_id"
              "scope.$"        = "$.chunk.result.scope"
            }
          }
          ResultSelector = {
            "result.$" = "$.Payload"
          }
          ResultPath = "$.recheck"
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
          Next = "CheckRecheckedScope"
        }

        CheckRecheckedScope = {
          Type = "Choice"
          Choices = [
            {
              Variable     = "$.recheck.result.status"
              StringEquals = "scope_clean"
              Next         = "CheckpointChunk"
            },
            {
              Variable     = "$.recheck.result.status"
              StringEquals = "scope_ready"
              Next         = "SelectMergeConsumer"
            },
            {
              Variable     = "$.recheck.result.status"
              StringEquals = "scope_split"
              Next         = "ReplayPlanDrift"
            },
          ]
          Default = "UnexpectedReplayResult"
        }

        SelectMergeConsumer = {
          Type = "Choice"
          Choices = [
            {
              Variable     = "$.consumer"
              StringEquals = "AC"
              Next         = "ReplayAcPosition"
            },
            {
              Variable     = "$.consumer"
              StringEquals = "EMDI"
              Next         = "ReplayEmdiPosition"
            },
          ]
          Default = "UnsupportedConsumer"
        }

        ReplayAcPosition = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_ac_position[0].lambda_function_arn
            "Payload.$" = "$.recheck.result.replay_input"
          }
          ResultPath = "$.merge_result"
          Retry = [
            {
              ErrorEquals = [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException",
              ]
              IntervalSeconds = 5
              BackoffRate     = 2
              MaxAttempts     = 3
            }
          ]
          Next = "VerifyReplayChunk"
        }

        ReplayEmdiPosition = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_emdi_position[0].lambda_function_arn
            "Payload.$" = "$.recheck.result.replay_input"
          }
          ResultPath = "$.merge_result"
          Retry = [
            {
              ErrorEquals = [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException",
              ]
              IntervalSeconds = 5
              BackoffRate     = 2
              MaxAttempts     = 3
            }
          ]
          Next = "VerifyReplayChunk"
        }

        VerifyReplayChunk = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action            = "verify_scope"
              "consumer.$"     = "$.consumer"
              "mode.$"         = "$.mode"
              "execution_id.$" = "$.execution_id"
              "scope.$"        = "$.recheck.result.scope"
            }
          }
          ResultSelector = {
            "result.$" = "$.Payload"
          }
          ResultPath = "$.verification"
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
          Next = "CheckVerification"
        }

        CheckVerification = {
          Type = "Choice"
          Choices = [
            {
              Variable     = "$.verification.result.status"
              StringEquals = "verified"
              Next         = "CheckpointChunk"
            },
            {
              Variable     = "$.verification.result.status"
              StringEquals = "verification_failed"
              Next         = "VerificationFailed"
            },
          ]
          Default = "UnexpectedVerificationResult"
        }

        CheckpointChunk = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action             = "checkpoint"
              "consumer.$"      = "$.consumer"
              "mode.$"          = "$.mode"
              "execution_id.$"  = "$.execution_id"
              "chunk_index.$"   = "$.chunk.result.chunk_index"
              "recovered.$"     = "$.recheck.result.missing_rows"
            }
          }
          ResultSelector = {
            "result.$" = "$.Payload"
          }
          ResultPath = "$.checkpoint"
          Next       = "NextReplayChunk"
        }

        CompleteExecution = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"
          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn
            Payload = {
              action            = "complete"
              "consumer.$"     = "$.consumer"
              "mode.$"         = "$.mode"
              "execution_id.$" = "$.execution_id"
            }
          }
          OutputPath = "$.Payload"
          Next       = "Complete"
        }

        Complete = {
          Type = "Succeed"
        }

        Rejected = {
          Type = "Succeed"
        }

        ApprovalExpired = {
          Type = "Succeed"
        }

        UnsupportedMode = {
          Type  = "Fail"
          Error = "UnsupportedReconciliationMode"
          Cause = "The reconciliation mode is not supported."
        }

        UnsupportedConsumer = {
          Type  = "Fail"
          Error = "UnsupportedReconciliationConsumer"
          Cause = "The reconciliation consumer is not supported."
        }

        ReplayPlanDrift = {
          Type  = "Fail"
          Error = "ReconciliationPlanDrift"
          Cause = "A replay chunk exceeded its approved scope before execution."
        }

        VerificationFailed = {
          Type  = "Fail"
          Error = "ReconciliationVerificationFailed"
          Cause = "Eligible positions remain after bounded replay."
        }

        UnexpectedPlanningResult = {
          Type  = "Fail"
          Error = "UnexpectedReconciliationPlanningResult"
          Cause = "The planner returned an unexpected planning status."
        }

        UnexpectedApprovalDecision = {
          Type  = "Fail"
          Error = "UnexpectedReconciliationApprovalDecision"
          Cause = "The approval callback returned an unexpected decision."
        }

        UnexpectedReplayResult = {
          Type  = "Fail"
          Error = "UnexpectedReconciliationReplayResult"
          Cause = "The planner returned an unexpected replay status."
        }

        UnexpectedVerificationResult = {
          Type  = "Fail"
          Error = "UnexpectedReconciliationVerificationResult"
          Cause = "The planner returned an unexpected verification status."
        }
      }
    }
  )
}


# ------------------------------------------
# Trigger cadt Step funtion
# ------------------------------------------

module "trigger_cadt_step_function" {
  source       = "./modules/step_function"
  name         = "trigger-create-a-derived-table"
  iam_policies = tomap({ "trigger_cadt_step_function_policy" = aws_iam_policy.trigger_cadt_step_function_policy })
  variable_dictionary = tomap(
    {
      "trigger_cadt"  = module.trigger_cadt.lambda_function_name,
      "environment"   = local.environment,
      "poll_cadt"     = module.poll_cadt.lambda_function_name,
    }
  )
  type = "STANDARD"
}


