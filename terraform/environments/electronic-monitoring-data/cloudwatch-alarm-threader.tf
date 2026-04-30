# ------------------------------------------------------------------------------
# Incident-threaded Slack notifications for CloudWatch alarms
#
# - Triggered by EventBridge "CloudWatch Alarm State Change"
# - Uses S3 as state store:
#   alarm-threading/current/<env>/<alarm_name>.json
# - Publishes Amazon Q custom notifications to the existing emds_alerts SNS topic
# - Starts the staged DB janitor Step Functions workflow only for the
#   glue_database_count_high alarm
# ------------------------------------------------------------------------------

locals {
  # State bucket for incident-threading state
  # Use the environment's logging bucket created by this stack
  alarm_thread_state_bucket = module.s3-logging-bucket.bucket.id

  alarm_thread_state_prefix = "alarm-threading/current"
}

# ------------------------------------------------------------------------------
# EventBridge: CloudWatch alarm state changes -> Lambda
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "alarm_state_change_threader" {
  name = "emds-alarm-state-change-threader-${local.environment_shorthand}"

  description = "Routes CloudWatch ALARM/OK state changes to cloudwatch_alarm_threader for incident-threaded Slack notifications"

  event_pattern = jsonencode(
    {
      "source" : ["aws.cloudwatch"],
      "detail-type" : ["CloudWatch Alarm State Change"],
      "detail" : {
        "alarmName" : concat(
          [
            aws_cloudwatch_metric_alarm.glue_database_count_high.alarm_name,
            aws_cloudwatch_metric_alarm.mdss_reconciler_errors_alarm[0].alarm_name
          ],
          [
            for _, alarm in aws_cloudwatch_metric_alarm.sqs_dlq_has_messages :
            alarm.alarm_name
          ]
        )
      }
    }
  )
}

resource "aws_cloudwatch_event_target" "alarm_state_change_threader" {
  rule = aws_cloudwatch_event_rule.alarm_state_change_threader.name
  arn  = module.cloudwatch_alarm_threader.lambda_function_arn
}

resource "aws_lambda_permission" "alarm_state_change_threader_allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridgeAlarmStateChange"
  action        = "lambda:InvokeFunction"
  function_name = module.cloudwatch_alarm_threader.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alarm_state_change_threader.arn
}

# ------------------------------------------------------------------------------
# Step Functions: staged DB janitor workflow
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "staging_db_janitor_sfn_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "staging_db_janitor_state_machine" {
  name = "staging_db_janitor_state_machine_role"

  assume_role_policy = (
    data.aws_iam_policy_document.staging_db_janitor_sfn_assume.json
  )
}

resource "aws_iam_role_policy" "staging_db_janitor_state_machine_invoke" {
  name = "staging_db_janitor_state_machine_invoke_policy"
  role = aws_iam_role.staging_db_janitor_state_machine.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "AllowInvokeStagingDbJanitorLambda"
          Effect = "Allow"
          Action = [
            "lambda:InvokeFunction"
          ]
          Resource = [
            module.staging_db_janitor.lambda_function_arn
          ]
        }
      ]
    }
  )
}

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
              "thread_id.$" = "$.thread_id"
              "alarm_name.$" = "$.alarm_name"
              "batch_number.$" = "$.batch_number"
              "stale_minutes.$" = "$.stale_minutes"
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
            "thread_id.$" = "$.thread_id"
            "alarm_name.$" = "$.alarm_name"
            "batch_number.$" = "$.next_batch_number"
            "stale_minutes.$" = "$.stale_minutes"
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