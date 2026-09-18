data "archive_file" "runtime_control" {
  count = local.dms_core_enabled ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/runtime/lambda_function.py"
  output_path = "${path.module}/runtime/lambda_function.zip"
}

data "aws_iam_policy_document" "runtime_control_assume_role" {
  count = local.dms_core_enabled ? 1 : 0

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

resource "aws_iam_role" "runtime_control" {
  count = local.dms_core_enabled ? 1 : 0

  name_prefix = "dms-core-runtime-control-"

  assume_role_policy = data.aws_iam_policy_document.runtime_control_assume_role[0].json

  tags = merge(
    local.tags,
    {
      Name    = "${local.application_name}-${local.environment}-${local.component_name}-runtime-control"
      Purpose = "DMS endpoint preflight and task runtime control"
    }
  )
}

data "aws_iam_policy_document" "runtime_control" {
  count = local.dms_core_enabled ? 1 : 0

  statement {
    sid    = "SynchroniseSourceCredentials"
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction"
    ]

    resources = [
      module.dms_test_harness[0].credential_sync_lambda_function_arn
    ]
  }

  statement {
    sid    = "TestAndDescribeDMSConnection"
    effect = "Allow"

    actions = [
      "dms:DescribeConnections",
      "dms:TestConnection"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "StartOrResumeReplicationTask"
    effect = "Allow"

    actions = [
      "dms:StartReplicationTask"
    ]

    resources = [
      module.dms_source_ingestion[0].replication_tasks["full_load_and_cdc"].arn
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

resource "aws_iam_role_policy" "runtime_control" {
  count = local.dms_core_enabled ? 1 : 0

  #checkov:skip=CKV_AWS_355: AWS DMS DescribeConnections requires wildcard resource access. All mutating permissions remain scoped to the managed task.
  name_prefix = "dms-core-runtime-control-"
  role        = aws_iam_role.runtime_control[0].id
  policy      = data.aws_iam_policy_document.runtime_control[0].json
}

resource "aws_iam_role_policy_attachment" "runtime_control_logs" {
  count = local.dms_core_enabled ? 1 : 0

  role       = aws_iam_role.runtime_control[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "runtime_control" {
  count = local.dms_core_enabled ? 1 : 0

  #checkov:skip=CKV_AWS_50: X-Ray tracing is not required for this development integration-test controller.
  #checkov:skip=CKV_AWS_116: A DLQ is not required because this Lambda is invoked synchronously and reports failures to its caller.
  #checkov:skip=CKV_AWS_117: VPC attachment is not required because this Lambda only calls AWS APIs.
  #checkov:skip=CKV_AWS_272: Code signing is not required for this temporary development integration-test Lambda.

  function_name = "${local.application_name}-${local.environment}-${local.component_name}-runtime-control"

  role    = aws_iam_role.runtime_control[0].arn
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
      CREDENTIAL_SYNC_FUNCTION_ARN = module.dms_test_harness[0].credential_sync_lambda_function_arn
      REPLICATION_INSTANCE_ARN     = module.dms_source_ingestion[0].dms_replication_instance_arn
      SOURCE_ENDPOINT_ARN          = module.dms_source_ingestion[0].dms_source_endpoint_arn
      REPLICATION_TASK_ARN         = module.dms_source_ingestion[0].replication_tasks["full_load_and_cdc"].arn
    }
  }

  depends_on = [
    aws_iam_role_policy.runtime_control,
    aws_iam_role_policy_attachment.runtime_control_logs
  ]

  tags = merge(
    local.tags,
    {
      Name    = "${local.application_name}-${local.environment}-${local.component_name}-runtime-control"
      Purpose = "DMS endpoint preflight and task runtime control"
    }
  )
}
