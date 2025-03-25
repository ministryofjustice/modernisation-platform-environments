#tfsec:ignore:avd-aws-0057 https://github.com/ministryofjustice/observability-platform/issues/57
#tfsec:ignore:avd-aws-0066 AWS X-Ray instrumentation is not enabled in the function's code
module "grafana_api_key_rotator" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  #checkov:skip=CKV_AWS_258:Function is not invoked by URL

  source  = "terraform-aws-modules/lambda/aws"
  version = "7.20.1"

  publish        = true
  create_package = false

  function_name = "grafana-api-key-rotator"
  description   = "Rotates the Grafana API key used by Terraform"
  package_type  = "Image"
  memory_size   = 2048
  timeout       = 120
  image_uri     = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/observability-platform-grafana-api-key-rotator:${local.environment_configuration.grafana_api_key_rotator_version}"

  environment_variables = {
    WORKSPACE_API_KEY_NAME = "observability-platform-automation" #checkov:skip=CKV_SECRET_6:This a reference to a secret, not a secret itself
    WORKSPACE_ID           = module.managed_grafana.workspace_id
    SECRET_ID              = aws_secretsmanager_secret.grafana_api_key.id
  }

  attach_policy_statements = true
  policy_statements = {
    "grafana" = {
      sid    = "Grafana"
      effect = "Allow"
      actions = [
        "grafana:CreateWorkspaceApiKey",
        "grafana:DeleteWorkspaceApiKey"
      ]
      resources = [module.managed_grafana.workspace_arn]
    }
    "secretsmanager" = {
      sid       = "SecretsManager"
      effect    = "Allow"
      actions   = ["secretsmanager:UpdateSecret"]
      resources = [aws_secretsmanager_secret.grafana_api_key.arn]
    }
  }

  allowed_triggers = {
    "eventbridge" = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.grafana_api_key_rotator.arn
    }
  }
}


module "modernisation_platform_github" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  #checkov:skip=CKV_AWS_258:Function is not invoked by URL
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 6.0"

  function_name = "modernisation-platform-github-workflows"
  handler       = "modernisation_platform_github_workflows.lambda_handler"
  runtime       = "python3.9"
  source_path   = "lambda"

  memory_size = 256
  timeout     = 30
  publish     = true

  create_role = false
  lambda_role = aws_iam_role.lambda_exec.arn

  # Set the env var to reference the Secrets Manager value (deferred to runtime)
  environment_variables = {
    GITHUB_PAT = "/aws/reference/secretsmanager/observability-platform/modernisation-platform-github-pat:pat"
  }

}

# Function URL for calling the lambda from grafana
resource "aws_lambda_function_url" "github_workflow_lambda_url" {
  function_name      = module.modernisation_platform_github.lambda_function_name
  authorization_type = "AWS_IAM"

  cors {
    allow_origins     = ["https://${module.managed_grafana.workspace_id}.grafana-workspace.eu-west-2.amazonaws.com"]
    allow_methods     = ["GET"]
    allow_headers     = ["*"]
  }
}

resource "aws_lambda_permission" "allow_grafana_url" {
  statement_id            = "AllowGrafanaWorkspaceToInvokeFunctionUrl"
  action                  = "lambda:InvokeFunctionUrl"
  function_name           = module.modernisation_platform_github.lambda_function_name
  principal               = "iam.amazonaws.com"
  function_url_auth_type  = "AWS_IAM"
}
