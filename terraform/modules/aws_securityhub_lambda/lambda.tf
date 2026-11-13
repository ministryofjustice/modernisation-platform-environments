resource "aws_lambda_function" "securityhub_finding_issue" {
  #checkov:skip=CKV_AWS_272:code signing not required
  #checkov:skip=CKV_AWS_117:lambda only calls public HTTPS endpoints
  #checkov:skip=CKV_AWS_50:X-Ray tracing is not required
  function_name = "${var.project_name}-lambda"
  handler       = "handler.lambda_handler"
  memory_size   = var.lambda_memory_size
  role          = aws_iam_role.securityhub.arn
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout

  filename    = "${path.module}/build/securityhub-finding-issue.zip"
  kms_key_arn = aws_kms_key.securityhub.arn
  source_code_hash = sha256(join("", [
    filesha256("${path.module}/lambda/handler.py"),
    filesha256("${path.module}/lambda/requirements.txt"),
  ]))

  dead_letter_config {
    target_arn = aws_sqs_queue.securityhub_findings_dlq.arn
  }

  reserved_concurrent_executions = 1

  environment {
    variables = {
      GITHUB_IDENTITY                = var.github_identity
      GITHUB_ORG                     = var.github_org
      GITHUB_REPO                    = var.github_repo
      IGNORE_FINDINGS                = data.aws_ssm_parameter.securityhub_ignore_findings.value
      FINDING_SEVERITY_LABELS        = jsonencode(var.finding_severity_labels)
      FINDING_GRACE_PERIOD           = tostring(var.finding_grace_period)
      VALID_SEVERITY_LABELS          = jsonencode(var.valid_severity_labels)
      RESOURCE_KEYS_TO_EXCLUDE       = jsonencode(var.resource_keys_to_exclude)
      WEB_IDENTITY_AUDIENCE          = var.web_identity_audience
      WEB_IDENTITY_DURATION_SECONDS  = var.web_identity_duration_seconds
      WEB_IDENTITY_SIGNING_ALGORITHM = var.web_identity_signing_algorithm
    }
  }

  depends_on = [
    terraform_data.lambda_build,
    aws_iam_role_policy.securityhub_dlq,
    aws_iam_role_policy.securityhub_kms,
    aws_iam_role_policy.securityhub_web_identity,
    aws_iam_role_policy_attachment.securityhub_basic_execution,
    aws_kms_key_policy.securityhub,
  ]
}
