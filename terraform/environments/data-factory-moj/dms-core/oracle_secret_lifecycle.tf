resource "aws_iam_role" "oracle_runtime_control" {
  count = local.dms_core_enabled ? 1 : 0

  name_prefix = "dms-oracle-runtime-control-"

  assume_role_policy = data.aws_iam_policy_document.runtime_control_assume_role[0].json

  tags = merge(
    local.tags,
    {
      Name    = "${local.application_name}-${local.environment}-oracle-runtime-control"
      Purpose = "Oracle DMS endpoint preflight after credential rotation"
    }
  )
}

data "aws_iam_policy_document" "oracle_runtime_control" {
  #checkov:skip=CKV_AWS_356: AWS DMS connection testing requires wildcard resource access.
  count = local.dms_core_enabled ? 1 : 0

  statement {
    sid    = "TestAndDescribeOracleDMSConnection"
    effect = "Allow"

    actions = [
      "dms:DescribeConnections",
      "dms:TestConnection"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "StartOrResumeOracleReplicationTask"
    effect = "Allow"

    actions = [
      "dms:StartReplicationTask"
    ]

    resources = [
      module.oracle_source_ingestion[0].replication_tasks["full_load_and_cdc"].arn
    ]
  }

  statement {
    sid    = "DecryptEnvironmentVariables"
    effect = "Allow"

    actions = [
      "kms:Decrypt"
    ]

    resources = [
      data.aws_kms_key.general_shared.arn
    ]
  }
}

resource "aws_iam_role_policy" "oracle_runtime_control" {
  count = local.dms_core_enabled ? 1 : 0

  #checkov:skip=CKV_AWS_355: AWS DMS connection testing requires wildcard resource access.
  name_prefix = "dms-oracle-runtime-control-"
  role        = aws_iam_role.oracle_runtime_control[0].id
  policy      = data.aws_iam_policy_document.oracle_runtime_control[0].json
}

resource "aws_iam_role_policy_attachment" "oracle_runtime_control_logs" {
  count = local.dms_core_enabled ? 1 : 0

  role       = aws_iam_role.oracle_runtime_control[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "oracle_runtime_control" {
  count = local.dms_core_enabled ? 1 : 0

  #checkov:skip=CKV_AWS_50: X-Ray tracing is unnecessary for this development integration-test controller.
  #checkov:skip=CKV_AWS_116: EventBridge retries failed invocations and sends exhausted attempts to the managed failure queue.
  #checkov:skip=CKV_AWS_117: VPC attachment is unnecessary because this Lambda only calls AWS APIs.
  #checkov:skip=CKV_AWS_272: Code signing is unnecessary for this temporary development integration-test Lambda.

  function_name = "${local.application_name}-${local.environment}-oracle-runtime-control"

  role    = aws_iam_role.oracle_runtime_control[0].arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"

  kms_key_arn = data.aws_kms_key.general_shared.arn

  filename         = data.archive_file.runtime_control[0].output_path
  source_code_hash = data.archive_file.runtime_control[0].output_base64sha256

  timeout                        = 420
  memory_size                    = 128
  reserved_concurrent_executions = 1

  environment {
    variables = {
      REPLICATION_INSTANCE_ARN = module.oracle_source_ingestion[0].dms_replication_instance_arn
      SOURCE_ENDPOINT_ARN      = module.oracle_source_ingestion[0].dms_source_endpoint_arn
      REPLICATION_TASK_ARN     = module.oracle_source_ingestion[0].replication_tasks["full_load_and_cdc"].arn
    }
  }

  depends_on = [
    aws_iam_role_policy.oracle_runtime_control,
    aws_iam_role_policy_attachment.oracle_runtime_control_logs
  ]

  tags = merge(
    local.tags,
    {
      Name    = "${local.application_name}-${local.environment}-oracle-runtime-control"
      Purpose = "Oracle DMS endpoint preflight after credential rotation"
    }
  )
}

resource "aws_sqs_queue" "oracle_preflight_failures" {
  count = local.dms_core_enabled ? 1 : 0

  name_prefix = "dms-oracle-preflight-failures-"

  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true

  tags = merge(
    local.tags,
    {
      Name    = "${local.application_name}-${local.environment}-oracle-preflight-failures"
      Purpose = "Failed Oracle DMS endpoint preflight events"
    }
  )
}

resource "aws_cloudwatch_event_rule" "oracle_secret_current" {
  count = local.dms_core_enabled ? 1 : 0

  name = "${local.application_name}-${local.environment}-oracle-secret-current"

  description = "Run the Oracle DMS endpoint preflight when the active source credential changes."

  event_pattern = jsonencode({
    source      = ["aws.secretsmanager"]
    detail-type = ["Secret Label Updated"]

    detail = {
      name = [
        module.oracle_test_harness[0].dms_source_secret_name
      ]

      labelUpdated = ["AWSCURRENT"]
    }
  })

  tags = merge(
    local.tags,
    {
      Name    = "${local.application_name}-${local.environment}-oracle-secret-current"
      Purpose = "Oracle DMS endpoint preflight after credential rotation"
    }
  )
}

data "aws_iam_policy_document" "oracle_preflight_failure_queue" {
  count = local.dms_core_enabled ? 1 : 0

  statement {
    sid    = "AllowEventBridgeFailureDelivery"
    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.oracle_preflight_failures[0].arn
    ]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_cloudwatch_event_rule.oracle_secret_current[0].arn
      ]
    }
  }
}

resource "aws_sqs_queue_policy" "oracle_preflight_failures" {
  count = local.dms_core_enabled ? 1 : 0

  queue_url = aws_sqs_queue.oracle_preflight_failures[0].url
  policy    = data.aws_iam_policy_document.oracle_preflight_failure_queue[0].json
}

resource "aws_lambda_permission" "oracle_preflight_from_eventbridge" {
  count = local.dms_core_enabled ? 1 : 0

  statement_id  = "AllowOracleSecretPreflight"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.oracle_runtime_control[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.oracle_secret_current[0].arn
}

resource "aws_cloudwatch_event_target" "oracle_secret_preflight" {
  count = local.dms_core_enabled ? 1 : 0

  rule      = aws_cloudwatch_event_rule.oracle_secret_current[0].name
  target_id = "oracle-dms-endpoint-preflight"
  arn       = aws_lambda_function.oracle_runtime_control[0].arn

  input = jsonencode({
    action = "preflight"
  })

  retry_policy {
    maximum_event_age_in_seconds = 3600
    maximum_retry_attempts       = 3
  }

  dead_letter_config {
    arn = aws_sqs_queue.oracle_preflight_failures[0].arn
  }

  depends_on = [
    aws_lambda_permission.oracle_preflight_from_eventbridge,
    aws_sqs_queue_policy.oracle_preflight_failures
  ]
}

resource "aws_secretsmanager_secret_rotation" "oracle_dms_source" {
  count = local.dms_core_enabled ? 1 : 0

  secret_id           = module.oracle_test_harness[0].dms_source_secret_id
  rotation_lambda_arn = module.oracle_test_harness[0].rotation_lambda_function_arn
  rotate_immediately  = false

  rotation_rules {
    automatically_after_days = 7
  }

  depends_on = [
    aws_cloudwatch_event_target.oracle_secret_preflight
  ]
}