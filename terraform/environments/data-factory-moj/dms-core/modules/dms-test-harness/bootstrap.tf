data "archive_file" "bootstrap" {
  type = "zip"

  source_file = "${path.module}/bootstrap/lambda_function.py"
  output_path = "${path.module}/bootstrap/lambda_function.zip"
}

data "aws_iam_policy_document" "bootstrap_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bootstrap" {
  name_prefix = "dms-core-bootstrap-"

  assume_role_policy = data.aws_iam_policy_document.bootstrap_assume_role.json

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-bootstrap"
      Purpose = "DMS integration test bootstrap"
    }
  )
}

data "aws_iam_policy_document" "bootstrap" {
  statement {
    sid    = "ReadRDSMasterSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_db_instance.postgres.master_user_secret[0].secret_arn
    ]
  }

  statement {
    sid    = "ReadWriteDMSSourceSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.dms_source.arn
    ]
  }

  statement {
    sid    = "UseDMSSecretKMSKey"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey"
    ]

    resources = [
      var.kms_key_arn
    ]
  }

  statement {
    sid    = "SendCredentialSyncFailures"
    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.credential_sync_failures.arn
    ]
  }
}

resource "aws_iam_role_policy" "bootstrap" {
  name_prefix = "dms-core-bootstrap-"
  role        = aws_iam_role.bootstrap.id

  policy = data.aws_iam_policy_document.bootstrap.json
}

resource "aws_iam_role_policy_attachment" "bootstrap_logs" {
  role       = aws_iam_role.bootstrap.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "bootstrap" {
  # checkov:skip=CKV_AWS_50: X-Ray tracing is not required for this development integration-test credential synchronisation Lambda.
  # checkov:skip=CKV_AWS_116: Asynchronous failures are sent to the credential-sync SQS queue through aws_lambda_function_event_invoke_config.
  # checkov:skip=CKV_AWS_117: VPC attachment is not required because this bootstrap only calls AWS APIs and does not connect directly to the private RDS instance.
  # checkov:skip=CKV_AWS_272: Code signing is not required for this temporary development integration-test Lambda.

  function_name = "${var.name}-bootstrap"

  role    = aws_iam_role.bootstrap.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"

  kms_key_arn = var.kms_key_arn

  filename         = data.archive_file.bootstrap.output_path
  source_code_hash = data.archive_file.bootstrap.output_base64sha256

  timeout                        = 30
  memory_size                    = 128
  reserved_concurrent_executions = 1

  environment {
    variables = {
      RDS_SECRET_ARN = aws_db_instance.postgres.master_user_secret[0].secret_arn
      DMS_SECRET_ARN = aws_secretsmanager_secret.dms_source.arn
      DB_HOST        = aws_db_instance.postgres.address
      DB_PORT        = tostring(aws_db_instance.postgres.port)
    }
  }

  depends_on = [
    aws_iam_role_policy.bootstrap,
    aws_iam_role_policy_attachment.bootstrap_logs
  ]

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-bootstrap"
      Purpose = "DMS integration test bootstrap"
    }
  )
}

resource "aws_cloudwatch_event_rule" "rds_secret_rotation" {
  name_prefix = "${var.name}-rds-secret-rotation-"
  description = "Synchronises the DMS source secret when the RDS-managed credential changes."

  event_pattern = jsonencode({
    source      = ["aws.secretsmanager"]
    detail-type = ["Secret Label Updated"]

    resources = [
      aws_db_instance.postgres.master_user_secret[0].secret_arn
    ]

    detail = {
      labelUpdated = ["AWSCURRENT"]
    }
  })

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-rds-secret-rotation"
      Purpose = "DMS source credential synchronisation"
    }
  )
}

resource "aws_sqs_queue" "credential_sync_failures" {
  name_prefix = "${var.name}-credential-sync-failures-"

  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-credential-sync-failures"
      Purpose = "Failed DMS source credential synchronisation events"
    }
  )
}

resource "aws_cloudwatch_event_target" "sync_dms_source_secret" {
  rule      = aws_cloudwatch_event_rule.rds_secret_rotation.name
  target_id = "SyncDMSSourceSecret"
  arn       = aws_lambda_function.bootstrap.arn

  retry_policy {
    maximum_event_age_in_seconds = 3600
    maximum_retry_attempts       = 10
  }

  dead_letter_config {
    arn = aws_sqs_queue.credential_sync_failures.arn
  }

  depends_on = [
    aws_lambda_permission.rds_secret_rotation,
    aws_sqs_queue_policy.credential_sync_failures
  ]
}

resource "aws_lambda_function_event_invoke_config" "bootstrap" {
  function_name = aws_lambda_function.bootstrap.function_name

  maximum_event_age_in_seconds = 3600
  maximum_retry_attempts       = 2

  destination_config {
    on_failure {
      destination = aws_sqs_queue.credential_sync_failures.arn
    }
  }

  depends_on = [
    aws_iam_role_policy.bootstrap
  ]
}

resource "aws_cloudwatch_metric_alarm" "credential_sync_failures" {
  alarm_name        = "${var.name}-credential-sync-failures"
  alarm_description = "One or more DMS source credential synchronisation events require investigation."

  namespace   = "AWS/SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"

  dimensions = {
    QueueName = aws_sqs_queue.credential_sync_failures.name
  }

  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 1
  datapoints_to_alarm = 1

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1

  treat_missing_data = "notBreaching"

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-credential-sync-failures"
      Purpose = "DMS source credential synchronisation monitoring"
    }
  )
}

data "aws_iam_policy_document" "credential_sync_failure_queue" {
  statement {
    sid    = "AllowEventBridgeToSendFailedEvents"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.credential_sync_failures.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_cloudwatch_event_rule.rds_secret_rotation.arn
      ]
    }
  }
}

resource "aws_sqs_queue_policy" "credential_sync_failures" {
  queue_url = aws_sqs_queue.credential_sync_failures.id
  policy    = data.aws_iam_policy_document.credential_sync_failure_queue.json
}

resource "aws_lambda_permission" "rds_secret_rotation" {
  statement_id  = "AllowRDSSecretRotationEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bootstrap.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_secret_rotation.arn
}
