# trivy:ignore:AVD-AWS-0066
module "lambda_s3_log_processor" {
  count   = local.create_resources ? 1 : 0
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "s3-log-processor"
  handler       = "log_shipper.handler"
  runtime       = "python3.12"
  timeout       = 900
  memory_size   = 512

  create_role              = true
  attach_policies          = true
  attach_policy_statements = true
  number_of_policies       = 1
  policies                 = ["arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"]
  policy_statements = {
    kms_decrypt_s3 = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [aws_kms_key.workspacesweb_session_logs[0].arn]
    }
    logs_write = {
      effect    = "Allow"
      actions   = ["logs:CreateLogStream", "logs:DescribeLogStreams", "logs:PutLogEvents"]
      resources = [aws_cloudwatch_log_group.workspacesweb_session_logs[0].arn, "${aws_cloudwatch_log_group.workspacesweb_session_logs[0].arn}:log-stream:*"]
    }
    sqs_read = {
      effect    = "Allow"
      actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:GetQueueUrl", "sqs:ChangeMessageVisibility"]
      resources = [module.sqs_lambda_consumer[0].queue_arn]
    }
    s3_read = {
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["${module.s3_bucket_workspacesweb_session_logs[0].s3_bucket_arn}/firewall/AWSLogs/*"]
    }
  }

  create_package         = false
  local_existing_package = data.archive_file.lambda.output_path

  # Environment
  environment_variables = {
    LOG_GROUP_NAME = aws_cloudwatch_log_group.workspacesweb_session_logs[0].name
  }

  event_source_mapping = {
    s3_events_from_sqs = {
      event_source_arn                   = module.sqs_lambda_consumer[0].queue_arn
      enabled                            = true
      batch_size                         = 10
      maximum_batching_window_in_seconds = 5
      function_response_types            = ["ReportBatchItemFailures"]
      scaling_config = {
        maximum_concurrency = 10
      }
    }
  }
}