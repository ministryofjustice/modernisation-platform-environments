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

module "securityhub_metric_ingester" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.20.1"

  function_name = "securityhub-metric-ingester"
  description   = "Publishes enriched Security Hub metrics for Grafana"
  handler       = "app.handler"
  runtime       = "python3.12"
  memory_size   = 512
  timeout       = 120
  tags          = local.tags

  source_path = "${path.module}/lambda/securityhub_metrics"

  publish                           = true
  cloudwatch_logs_retention_in_days = 90

  environment_variables = {
    METRIC_NAMESPACE   = "ObservabilityPlatform/SecurityHub"
    METRIC_NAME        = "SecurityHubFindings"
    ACCOUNT_NAMES_JSON = jsonencode(local.securityhub_account_name_map)
  }

  attach_policy_statements = true
  policy_statements = {
    cloudwatch = {
      sid       = "AllowPutMetricData"
      effect    = "Allow"
      actions   = ["cloudwatch:PutMetricData"]
      resources = ["*"]
    }
  }

  allowed_triggers = {
    securityhub_events = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.securityhub_new_high_critical.arn
    }
  }
}
