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
  source              = "./modules/merge_into_reconciler"
  function_to_iterate = module.merge_mdss_staged_position[0]
}

# ------------------------------------------
# Merge into staged event step function
# ------------------------------------------

module "merge_into_mdss_staged_event" {
  source              = "./modules/merge_into_reconciler"
  function_to_iterate = module.merge_mdss_staged_event[0]
}

# ------------------------------------------
# Merge into emdi position step function
# ------------------------------------------

module "merge_into_emdi_position" {
  source              = "./modules/merge_into_reconciler"
  function_to_iterate = module.merge_emdi_position[0]
}

# ------------------------------------------
# Merge into ac position step function
# ------------------------------------------

module "merge_into_mdss_ac_position" {
  source              = "./modules/merge_into_reconciler"
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

# ------------------------------------------
# Trigger cadt Step funtion
# ------------------------------------------

module "trigger_cadt_step_function" {
  source       = "./modules/step_function"
  name         = "trigger-create-a-derived-table"
  iam_policies = tomap({ "trigger_cadt_step_function_policy" = aws_iam_policy.trigger_cadt_step_function_policy })
  variable_dictionary = tomap(
    {
      "trigger_cadt" = module.trigger_cadt.lambda_function_name,
      "environment"  = local.environment,
      "poll_cadt"    = module.poll_cadt.lambda_function_name,
    }
  )
  type = "STANDARD"
}

# ------------------------------------------------------------------------------
# Downstream position reconciliation Step Function
# ------------------------------------------------------------------------------

resource "aws_sfn_state_machine" "downstream_reconciliation" {
  name     = "downstream_position_reconciliation"
  role_arn = aws_iam_role.downstream_reconciliation_state_machine.arn

  definition = jsonencode(
    {
      Comment = "Runs rolling, ranged and full downstream position reconciliation."
      StartAt = "SelectInputMode"

      States = {
        SelectInputMode = {
          Type = "Choice"

          Choices = [
            {
              Variable     = "$.mode"
              StringEquals = "rolling"
              Next         = "DiscoverRolling"
            },
            {
              Variable     = "$.mode"
              StringEquals = "range"
              Next         = "StartHistoricalRange"
            },
            {
              Variable     = "$.mode"
              StringEquals = "full"
              Next         = "StartHistoricalFull"
            },
          ]

          Default = "UnsupportedMode"
        }

        DiscoverRolling = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"

          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn

            Payload = {
              action       = "discover_rolling"
              "consumer.$" = "$.consumer"
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

          Next = "CheckRollingDiscovery"
        }

        CheckRollingDiscovery = {
          Type = "Choice"

          Choices = [
            {
              Variable     = "$.status"
              StringEquals = "clean"
              Next         = "RollingComplete"
            },
            {
              Variable     = "$.status"
              StringEquals = "manual_review_required"
              Next         = "RollingManualReviewRequired"
            },
            {
              Variable     = "$.status"
              StringEquals = "replay_ready"
              Next         = "ReplayRollingCandidates"
            },
          ]

          Default = "UnexpectedRollingResult"
        }

        ReplayRollingCandidates = {
          Type           = "Map"
          ItemsPath      = "$.candidates"
          MaxConcurrency = 1
          ResultPath     = null

          ItemProcessor = {
            ProcessorConfig = {
              Mode = "INLINE"
            }

            StartAt = "SelectRollingConsumer"

            States = {
              SelectRollingConsumer = {
                Type = "Choice"

                Choices = [
                  {
                    Variable     = "$.consumer"
                    StringEquals = "STAGED"
                    Next         = "ReplayRollingStagedPosition"
                  },
                  {
                    Variable     = "$.consumer"
                    StringEquals = "AC"
                    Next         = "ReplayRollingAcPosition"
                  },
                  {
                    Variable     = "$.consumer"
                    StringEquals = "EMDI"
                    Next         = "ReplayRollingEmdiPosition"
                  },
                ]

                Default = "UnsupportedRollingConsumer"
              }

              ReplayRollingStagedPosition = {
                Type     = "Task"
                Resource = "arn:aws:states:::lambda:invoke"

                Parameters = {
                  FunctionName = module.merge_mdss_staged_position[0].lambda_function_arn
                  "Payload.$"  = "$.replay_input"
                }

                ResultPath = null

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

                Next = "VerifyRollingCandidate"
              }

              ReplayRollingAcPosition = {
                Type     = "Task"
                Resource = "arn:aws:states:::lambda:invoke"

                Parameters = {
                  FunctionName = module.merge_ac_position[0].lambda_function_arn
                  "Payload.$"  = "$.replay_input"
                }

                ResultPath = null

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

                Next = "VerifyRollingCandidate"
              }

              ReplayRollingEmdiPosition = {
                Type     = "Task"
                Resource = "arn:aws:states:::lambda:invoke"

                Parameters = {
                  FunctionName = module.merge_emdi_position[0].lambda_function_arn
                  "Payload.$"  = "$.replay_input"
                }

                ResultPath = null

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

                Next = "VerifyRollingCandidate"
              }

              VerifyRollingCandidate = {
                Type     = "Task"
                Resource = "arn:aws:states:::lambda:invoke"

                Parameters = {
                  FunctionName = module.merge_redrive_planner.lambda_function_arn

                  Payload = {
                    action        = "verify_rolling"
                    "candidate.$" = "$"
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

                Next = "CheckRollingVerification"
              }

              CheckRollingVerification = {
                Type = "Choice"

                Choices = [
                  {
                    Variable     = "$.status"
                    StringEquals = "verified"
                    Next         = "RollingCandidateVerified"
                  },
                  {
                    Variable     = "$.status"
                    StringEquals = "verification_failed"
                    Next         = "RollingVerificationFailed"
                  },
                ]

                Default = "UnexpectedRollingVerificationResult"
              }

              RollingCandidateVerified = {
                Type = "Succeed"
              }

              UnsupportedRollingConsumer = {
                Type  = "Fail"
                Error = "UnsupportedRollingReconciliationConsumer"
                Cause = "The rolling reconciliation consumer is not supported."
              }

              RollingVerificationFailed = {
                Type  = "Fail"
                Error = "RollingReconciliationVerificationFailed"
                Cause = "Stale positions remain after rolling replay."
              }

              UnexpectedRollingVerificationResult = {
                Type  = "Fail"
                Error = "UnexpectedRollingVerificationResult"
                Cause = "The planner returned an unexpected rolling verification status."
              }
            }
          }

          Next = "RollingComplete"
        }

        RollingComplete = {
          Type = "Succeed"
        }

        RollingManualReviewRequired = {
          Type = "Succeed"
        }

        StartHistoricalRange = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"

          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn

            Payload = {
              action         = "start_historical"
              "consumer.$"   = "$.consumer"
              "mode.$"       = "$.mode"
              "start_date.$" = "$.start_date"
              "end_date.$"   = "$.end_date"
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

          Next = "CheckHistoricalStart"
        }

        StartHistoricalFull = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"

          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn

            Payload = {
              action       = "start_historical"
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

          Next = "CheckHistoricalStart"
        }

        CheckHistoricalStart = {
          Type = "Choice"

          Choices = [
            {
              Variable     = "$.status"
              StringEquals = "planning"
              Next         = "PlanHistorical"
            },
            {
              Variable     = "$.status"
              StringEquals = "completed"
              Next         = "HistoricalComplete"
            },
          ]

          Default = "UnexpectedHistoricalPlanningResult"
        }

        PlanHistorical = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"

          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn

            Payload = {
              action           = "plan_historical"
              "consumer.$"     = "$.consumer"
              "execution_id.$" = "$.execution_id"
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

          Next = "CheckHistoricalPlanning"
        }

        CheckHistoricalPlanning = {
          Type = "Choice"

          Choices = [
            {
              Variable     = "$.status"
              StringEquals = "planning"
              Next         = "WaitBeforeHistoricalPlanning"
            },
            {
              Variable     = "$.status"
              StringEquals = "replay_ready"
              Next         = "NextHistoricalChunk"
            },
            {
              Variable     = "$.status"
              StringEquals = "approval_required"
              Next         = "WaitForHistoricalApproval"
            },
          ]

          Default = "UnexpectedHistoricalPlanningResult"
        }

        WaitBeforeHistoricalPlanning = {
          Type    = "Wait"
          Seconds = 1
          Next    = "PlanHistorical"
        }

        WaitForHistoricalApproval = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke.waitForTaskToken"

          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn

            Payload = {
              action           = "park_historical_approval"
              "consumer.$"     = "$.consumer"
              "execution_id.$" = "$.execution_id"
              "plan_id.$"      = "$.plan_id"
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

          Next = "RecordHistoricalApproval"
        }

        RecordHistoricalApproval = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"

          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn

            Payload = {
              action           = "record_historical_approval"
              "consumer.$"     = "$.consumer"
              "execution_id.$" = "$.execution_id"
              "plan_id.$"      = "$.plan_id"
              "decision.$"     = "$.approval.decision"
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

          Next = "CheckHistoricalApproval"
        }

        CheckHistoricalApproval = {
          Type = "Choice"

          Choices = [
            {
              Variable     = "$.status"
              StringEquals = "replay_ready"
              Next         = "NextHistoricalChunk"
            },
            {
              Variable     = "$.status"
              StringEquals = "rejected"
              Next         = "HistoricalRejected"
            },
          ]

          Default = "UnexpectedHistoricalApprovalResult"
        }

        NextHistoricalChunk = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"

          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn

            Payload = {
              action           = "next_historical_chunk"
              "consumer.$"     = "$.consumer"
              "execution_id.$" = "$.execution_id"
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

          Next = "CheckHistoricalChunk"
        }

        CheckHistoricalChunk = {
          Type = "Choice"

          Choices = [
            {
              Variable     = "$.status"
              StringEquals = "chunk_ready"
              Next         = "SelectHistoricalConsumer"
            },
            {
              Variable     = "$.status"
              StringEquals = "complete"
              Next         = "CompleteHistorical"
            },
            {
              Variable     = "$.status"
              StringEquals = "approval_required"
              Next         = "WaitForHistoricalApproval"
            },
          ]

          Default = "UnexpectedHistoricalReplayResult"
        }

        SelectHistoricalConsumer = {
          Type = "Choice"

          Choices = [
            {
              Variable     = "$.consumer"
              StringEquals = "AC"
              Next         = "ReplayHistoricalAcPosition"
            },
            {
              Variable     = "$.consumer"
              StringEquals = "EMDI"
              Next         = "ReplayHistoricalEmdiPosition"
            },
          ]

          Default = "UnsupportedHistoricalConsumer"
        }

        ReplayHistoricalAcPosition = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"

          Parameters = {
            FunctionName = module.merge_ac_position[0].lambda_function_arn
            "Payload.$"  = "$.replay_input"
          }

          ResultPath = null

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

          Next = "VerifyHistoricalChunk"
        }

        ReplayHistoricalEmdiPosition = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"

          Parameters = {
            FunctionName = module.merge_emdi_position[0].lambda_function_arn
            "Payload.$"  = "$.replay_input"
          }

          ResultPath = null

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

          Next = "VerifyHistoricalChunk"
        }

        VerifyHistoricalChunk = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"

          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn

            Payload = {
              action           = "verify_historical_chunk"
              "consumer.$"     = "$.consumer"
              "execution_id.$" = "$.execution_id"
              "chunk_index.$"  = "$.chunk_index"
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

          Next = "CheckHistoricalVerification"
        }

        CheckHistoricalVerification = {
          Type = "Choice"

          Choices = [
            {
              Variable     = "$.status"
              StringEquals = "verified"
              Next         = "CheckpointHistoricalChunk"
            },
            {
              Variable     = "$.status"
              StringEquals = "verification_failed"
              Next         = "HistoricalVerificationFailed"
            },
          ]

          Default = "UnexpectedHistoricalVerificationResult"
        }

        CheckpointHistoricalChunk = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"

          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn

            Payload = {
              action                    = "checkpoint_historical"
              "consumer.$"              = "$.consumer"
              "execution_id.$"          = "$.execution_id"
              "chunk_index.$"           = "$.chunk_index"
              "verification_status.$"   = "$.status"
              "positions_recovered.$"   = "$.positions_recovered"
              "data_scanned_in_bytes.$" = "$.data_scanned_in_bytes"
              "period.$"                = "$.period"
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

          Next = "NextHistoricalChunk"
        }

        CompleteHistorical = {
          Type     = "Task"
          Resource = "arn:aws:states:::lambda:invoke"

          Parameters = {
            FunctionName = module.merge_redrive_planner.lambda_function_arn

            Payload = {
              action           = "complete_historical"
              "consumer.$"     = "$.consumer"
              "execution_id.$" = "$.execution_id"
            }
          }

          OutputPath = "$.Payload"
          Next       = "HistoricalComplete"
        }

        HistoricalComplete = {
          Type = "Succeed"
        }

        HistoricalRejected = {
          Type = "Succeed"
        }

        UnsupportedMode = {
          Type  = "Fail"
          Error = "UnsupportedReconciliationMode"
          Cause = "The reconciliation mode must be rolling, range or full."
        }

        UnsupportedHistoricalConsumer = {
          Type  = "Fail"
          Error = "UnsupportedHistoricalReconciliationConsumer"
          Cause = "Historical reconciliation only supports AC and EMDI."
        }

        UnexpectedRollingResult = {
          Type  = "Fail"
          Error = "UnexpectedRollingReconciliationResult"
          Cause = "The planner returned an unexpected rolling status."
        }

        UnexpectedHistoricalPlanningResult = {
          Type  = "Fail"
          Error = "UnexpectedHistoricalPlanningResult"
          Cause = "The planner returned an unexpected historical planning status."
        }

        UnexpectedHistoricalApprovalResult = {
          Type  = "Fail"
          Error = "UnexpectedHistoricalApprovalResult"
          Cause = "The historical approval callback returned an unexpected result."
        }

        UnexpectedHistoricalReplayResult = {
          Type  = "Fail"
          Error = "UnexpectedHistoricalReplayResult"
          Cause = "The planner returned an unexpected historical replay status."
        }

        HistoricalVerificationFailed = {
          Type  = "Fail"
          Error = "HistoricalReconciliationVerificationFailed"
          Cause = "Eligible positions remain after historical replay."
        }

        UnexpectedHistoricalVerificationResult = {
          Type  = "Fail"
          Error = "UnexpectedHistoricalVerificationResult"
          Cause = "The planner returned an unexpected historical verification status."
        }
      }
    }
  )
}
