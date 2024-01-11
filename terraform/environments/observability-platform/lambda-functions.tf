module "grafana_api_key_rotator" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 6.0"

  publish = true

  function_name = "grafana-api-key-rotator"
  handler       = "index.lambda_handler"
  runtime       = "python3.12"

  source_path = "${path.module}/src/lambda/grafana-api-key-rotator"

  environment_variables = {
    WORKSPACE_API_KEY_NAME = "observability-platform-automation"
    WORKSPACE_ID           = module.managed_grafana.workspace_id
    SECRET_ID              = aws_secretsmanager_secret.grafana_api_key.id
  }

  attach_policy_statements = true
  policy_statements = {
    "amazonmanagedgrafana" = {
      sid    = "AmazonManagedGrafana"
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
}
