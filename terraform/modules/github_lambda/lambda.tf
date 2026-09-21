resource "aws_lambda_function" "github_workflow_trigger" {
  function_name = "${var.project_name}-trigger"
  handler       = "handler.lambda_handler"
  memory_size   = var.lambda_memory_size
  role          = aws_iam_role.lambda.arn
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout

  filename         = "${path.module}/build/github-workflow-trigger.zip"
  source_code_hash = filebase64sha256("${path.module}/build/github-workflow-trigger.zip")

  environment {
    variables = {
      GITHUB_APP_SECRET_ARN = aws_secretsmanager_secret.github_app.arn
      GITHUB_ORG            = var.github_org
    }
  }

  depends_on = [
    terraform_data.lambda_build,
    aws_iam_role_policy.lambda_secrets_manager,
    aws_iam_role_policy_attachment.lambda_basic_execution,
  ]
}
