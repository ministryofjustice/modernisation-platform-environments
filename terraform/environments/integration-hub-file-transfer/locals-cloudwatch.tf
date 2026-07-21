locals {
  cloudwatch_guardduty_malware_protection_dimensions = {
    "Malware Protection Plan Id" = aws_guardduty_malware_protection_plan.this.id
    "Resource Name"              = module.s3_bucket["processing"].s3_bucket_id
  }

  cloudwatch_metric_alarms = {
    "lambda-file-received-adapter-errors" = {
      alarm_description   = "The file received adapter Lambda function has failed to process one or more events"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        FunctionName = module.lambda_file_received_adapter.lambda_function_name
      }
      evaluation_periods = 1
      metric_name        = "Errors"
      namespace          = "AWS/Lambda"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "lambda-file-received-adapter-throttles" = {
      alarm_description   = "The file received adapter Lambda function has been throttled"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        FunctionName = module.lambda_file_received_adapter.lambda_function_name
      }
      evaluation_periods = 1
      metric_name        = "Throttles"
      namespace          = "AWS/Lambda"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "lambda-file-received-adapter-duration" = {
      alarm_description   = "The file received adapter Lambda function duration is approaching its timeout"
      comparison_operator = "GreaterThanThreshold"
      datapoints_to_alarm = 2
      dimensions = {
        FunctionName = module.lambda_file_received_adapter.lambda_function_name
      }
      evaluation_periods = 2
      metric_name        = "Duration"
      namespace          = "AWS/Lambda"
      period             = 300
      statistic          = "Average"
      threshold          = 25000
    }
    "lambda-file-received-adapter-dead-letter-errors" = {
      alarm_description   = "The file received adapter Lambda function could not send a failed event to its dead-letter queue"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        FunctionName = module.lambda_file_received_adapter.lambda_function_name
      }
      evaluation_periods = 1
      metric_name        = "DeadLetterErrors"
      namespace          = "AWS/Lambda"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "lambda-file-scan-result-recorded-adapter-errors" = {
      alarm_description   = "The file scan result recorded adapter Lambda function has failed to process one or more events"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        FunctionName = module.lambda_file_scan_result_recorded_adapter.lambda_function_name
      }
      evaluation_periods = 1
      metric_name        = "Errors"
      namespace          = "AWS/Lambda"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "lambda-file-scan-result-recorded-adapter-throttles" = {
      alarm_description   = "The file scan result recorded adapter Lambda function has been throttled"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        FunctionName = module.lambda_file_scan_result_recorded_adapter.lambda_function_name
      }
      evaluation_periods = 1
      metric_name        = "Throttles"
      namespace          = "AWS/Lambda"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "lambda-file-scan-result-recorded-adapter-duration" = {
      alarm_description   = "The file scan result recorded adapter Lambda function duration is approaching its timeout"
      comparison_operator = "GreaterThanThreshold"
      datapoints_to_alarm = 2
      dimensions = {
        FunctionName = module.lambda_file_scan_result_recorded_adapter.lambda_function_name
      }
      evaluation_periods = 2
      metric_name        = "Duration"
      namespace          = "AWS/Lambda"
      period             = 300
      statistic          = "Average"
      threshold          = 25000
    }
    "lambda-file-scan-result-recorded-adapter-dead-letter-errors" = {
      alarm_description   = "The file scan result recorded adapter Lambda function could not send a failed event to its dead-letter queue"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        FunctionName = module.lambda_file_scan_result_recorded_adapter.lambda_function_name
      }
      evaluation_periods = 1
      metric_name        = "DeadLetterErrors"
      namespace          = "AWS/Lambda"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "eventbridge-default-rule-failed-invocations" = {
      alarm_description   = "The incoming S3 Object Created EventBridge rule has failed to invoke its target"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        RuleName = module.eventbridge_default_bus.eventbridge_rules["incoming-s3-object-created"].name
      }
      evaluation_periods = 1
      metric_name        = "FailedInvocations"
      namespace          = "AWS/Events"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "eventbridge-default-dlq-visible-messages" = {
      alarm_description   = "The default EventBridge rule dead-letter queue contains failed events"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        QueueName = module.sqs_eventbridge_default_dlq.queue_name
      }
      evaluation_periods = 1
      metric_name        = "ApproximateNumberOfMessagesVisible"
      namespace          = "AWS/SQS"
      period             = 300
      statistic          = "Maximum"
      threshold          = 0
    }
    "eventbridge-guardduty-malware-scan-result-failed-invocations" = {
      alarm_description   = "The GuardDuty malware scan result EventBridge rule has failed to invoke its target"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        RuleName = module.eventbridge_default_bus.eventbridge_rules["guardduty-malware-scan-result"].name
      }
      evaluation_periods = 1
      metric_name        = "FailedInvocations"
      namespace          = "AWS/Events"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "eventbridge-file-transfer-workflow-failed-invocations" = {
      alarm_description   = "The FileReceived.v1 EventBridge rule has failed to start the file transfer workflow"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        EventBusName = module.eventbridge_file_transfer_bus.eventbridge_bus_name
        RuleName     = module.eventbridge_file_transfer_bus.eventbridge_rules["file-transfer-workflow"].name
      }
      evaluation_periods = 1
      metric_name        = "FailedInvocations"
      namespace          = "AWS/Events"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "eventbridge-file-transfer-workflow-dlq-visible-messages" = {
      alarm_description   = "The file transfer workflow EventBridge dead-letter queue contains failed events"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        QueueName = module.sqs_eventbridge_file_transfer_workflow_dlq.queue_name
      }
      evaluation_periods = 1
      metric_name        = "ApproximateNumberOfMessagesVisible"
      namespace          = "AWS/SQS"
      period             = 300
      statistic          = "Maximum"
      threshold          = 0
    }
    "step-functions-file-transfer-workflow-failures" = {
      alarm_description   = "The file transfer workflow has failed one or more executions"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        StateMachineArn = module.step_function_filereceived_workflow.state_machine_arn
      }
      evaluation_periods = 1
      metric_name        = "ExecutionsFailed"
      namespace          = "AWS/States"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "step-functions-file-transfer-workflow-timeouts" = {
      alarm_description   = "The file transfer workflow has timed out one or more executions"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        StateMachineArn = module.step_function_filereceived_workflow.state_machine_arn
      }
      evaluation_periods = 1
      metric_name        = "ExecutionsTimedOut"
      namespace          = "AWS/States"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "step-functions-file-transfer-workflow-aborts" = {
      alarm_description   = "The file transfer workflow has aborted one or more executions"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        StateMachineArn = module.step_function_filereceived_workflow.state_machine_arn
      }
      evaluation_periods = 1
      metric_name        = "ExecutionsAborted"
      namespace          = "AWS/States"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "step-functions-file-transfer-workflow-throttles" = {
      alarm_description   = "The file transfer workflow has experienced state transition throttling"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        StateMachineArn = module.step_function_filereceived_workflow.state_machine_arn
      }
      evaluation_periods = 1
      metric_name        = "ExecutionThrottled"
      namespace          = "AWS/States"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "dynamodb-file-transfer-workflow-idempotency-read-throttles" = {
      alarm_description   = "The file transfer workflow idempotency table has throttled one or more read requests"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        TableName = module.dynamodb_file_transfer_idempotency.dynamodb_table_id
      }
      evaluation_periods = 1
      metric_name        = "ReadThrottleEvents"
      namespace          = "AWS/DynamoDB"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "dynamodb-file-transfer-workflow-idempotency-write-throttles" = {
      alarm_description   = "The file transfer workflow idempotency table has throttled one or more write requests"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        TableName = module.dynamodb_file_transfer_idempotency.dynamodb_table_id
      }
      evaluation_periods = 1
      metric_name        = "WriteThrottleEvents"
      namespace          = "AWS/DynamoDB"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "lambda-file-received-adapter-dlq-visible-messages" = {
      alarm_description   = "The file received adapter Lambda dead-letter queue contains failed events"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        QueueName = module.sqs_lambda_file_received_adapter_dlq.queue_name
      }
      evaluation_periods = 1
      metric_name        = "ApproximateNumberOfMessagesVisible"
      namespace          = "AWS/SQS"
      period             = 300
      statistic          = "Maximum"
      threshold          = 0
    }
    "lambda-file-scan-result-recorded-adapter-dlq-visible-messages" = {
      alarm_description   = "The file scan result recorded adapter Lambda dead-letter queue contains failed events"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        QueueName = module.sqs_lambda_file_scan_result_recorded_adapter_dlq.queue_name
      }
      evaluation_periods = 1
      metric_name        = "ApproximateNumberOfMessagesVisible"
      namespace          = "AWS/SQS"
      period             = 300
      statistic          = "Maximum"
      threshold          = 0
    }
    "dynamodb-idempotency-read-throttles" = {
      alarm_description   = "The adapter idempotency DynamoDB table has throttled one or more read requests"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        TableName = module.dynamodb_adapter_idempotency.dynamodb_table_id
      }
      evaluation_periods = 1
      metric_name        = "ReadThrottleEvents"
      namespace          = "AWS/DynamoDB"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "dynamodb-idempotency-write-throttles" = {
      alarm_description   = "The adapter idempotency DynamoDB table has throttled one or more write requests"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        TableName = module.dynamodb_adapter_idempotency.dynamodb_table_id
      }
      evaluation_periods = 1
      metric_name        = "WriteThrottleEvents"
      namespace          = "AWS/DynamoDB"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "guardduty-failed-scans" = {
      alarm_description   = "GuardDuty Malware Protection for S3 failed to scan one or more objects"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = local.cloudwatch_guardduty_malware_protection_dimensions
      evaluation_periods  = 1
      metric_name         = "FailedScanCount"
      namespace           = "AWS/GuardDuty/MalwareProtection"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
    }
    "guardduty-infected-scans" = {
      alarm_description   = "GuardDuty Malware Protection for S3 found one or more potentially malicious objects"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = local.cloudwatch_guardduty_malware_protection_dimensions
      evaluation_periods  = 1
      metric_name         = "InfectedScanCount"
      namespace           = "AWS/GuardDuty/MalwareProtection"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
    }
    "guardduty-skipped-scans-missing-permissions" = {
      alarm_description   = "GuardDuty Malware Protection for S3 skipped one or more objects due to missing permissions"
      comparison_operator = "GreaterThanThreshold"
      dimensions = merge(local.cloudwatch_guardduty_malware_protection_dimensions, {
        "Skipped Reason" = "MissingPermissions"
      })
      evaluation_periods = 1
      metric_name        = "SkippedScanCount"
      namespace          = "AWS/GuardDuty/MalwareProtection"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
    "guardduty-skipped-scans-unsupported" = {
      alarm_description   = "GuardDuty Malware Protection for S3 skipped one or more unsupported objects"
      comparison_operator = "GreaterThanThreshold"
      dimensions = merge(local.cloudwatch_guardduty_malware_protection_dimensions, {
        "Skipped Reason" = "Unsupported"
      })
      evaluation_periods = 1
      metric_name        = "SkippedScanCount"
      namespace          = "AWS/GuardDuty/MalwareProtection"
      period             = 300
      statistic          = "Sum"
      threshold          = 0
    }
  }

  cloudwatch_retention_days = local.is-production ? 400 : 30
}
