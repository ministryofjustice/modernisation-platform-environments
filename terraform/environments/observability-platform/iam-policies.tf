
data "aws_iam_policy_document" "amazon_managed_grafana_remote_cloudwatch" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      for account in local.all_aws_accounts : format(
        "arn:aws:iam::%s:role/observability-platform",
        account == "modernisation-platform" ? local.environment_management.modernisation_platform_account_id : local.environment_management.account_ids[account]
      )
    ]
  }
}

module "amazon_managed_grafana_remote_cloudwatch_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.52.2"

  name_prefix = "amazon-managed-grafana-remote-cloudwatch"

  policy = data.aws_iam_policy_document.amazon_managed_grafana_remote_cloudwatch.json
}


# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_exec_secrets_access" {
  name = "lambda-exec-secrets-access"
  role = aws_iam_role.lambda_exec.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = aws_secretsmanager_secret.modernisation_platform_github_pat.arn
      }
    ]
  })
}

# IAM Policy for Grafana to Invoke Lambda
data "aws_iam_policy_document" "grafana_lambda_invoke" {
  statement {
    sid     = "AllowInvokeLambdaFunctionURL"
    effect  = "Allow"
    actions = ["lambda:InvokeFunctionUrl"]
    resources = [
      module.modernisation_platform_github.lambda_function_arn
    ]
    condition {
      test     = "StringEquals"
      variable = "lambda:FunctionUrlAuthType"
      values   = ["AWS_IAM"]
    }
  }
}

resource "aws_iam_policy" "grafana_lambda_policy" {
  name   = "grafana-invoke-lambda-url"
  policy = data.aws_iam_policy_document.grafana_lambda_invoke.json
}

resource "aws_iam_role_policy_attachment" "grafana_can_invoke_lambda_url" {
  role       = module.managed_grafana.workspace_iam_role_name
  policy_arn = aws_iam_policy.grafana_lambda_policy.arn
}
