resource "aws_lambda_function" "github_workflow_trigger" {
  #checkov:skip=CKV_AWS_272:code signing not required
  #checkov:skip=CKV_AWS_117:lambda only calls public HTTPS endpoints
  function_name = "${var.project_name}-trigger"
  handler       = "handler.lambda_handler"
  memory_size   = var.lambda_memory_size
  role          = aws_iam_role.lambda.arn
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout

  filename    = "${path.module}/build/github-workflow-trigger.zip"
  kms_key_arn = aws_kms_key.lambda.arn
  source_code_hash = sha256(join("", [
    filesha256("${path.module}/lambda/handler.py"),
    filesha256("${path.module}/lambda/requirements.txt"),
  ]))

  dead_letter_config {
    target_arn = aws_sqs_queue.github_workflow_dlq.arn
  }

  reserved_concurrent_executions = 1

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      GITHUB_ORG                     = var.github_org
      WEB_IDENTITY_AUDIENCE          = var.web_identity_audience
      WEB_IDENTITY_DURATION_SECONDS  = var.web_identity_duration_seconds
      WEB_IDENTITY_SIGNING_ALGORITHM = var.web_identity_signing_algorithm
    }
  }

  depends_on = [
    terraform_data.lambda_build,
    aws_iam_role_policy.lambda_dlq,
    aws_iam_role_policy.lambda_kms,
    aws_iam_role_policy.lambda_web_identity,
    aws_iam_role_policy_attachment.lambda_basic_execution,
  ]
}
