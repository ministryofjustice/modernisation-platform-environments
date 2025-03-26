locals {
  grafana_workspace_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/AmazonGrafana-WorkspaceRole-${module.managed_grafana.workspace_id}"
}

resource "aws_lambda_function" "sigv4_proxy" {
  function_name = "sigv4-proxy"
  package_type  = "Image"
  image_uri     = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/observability-platform-grafana-sigv4-proxy:latest"
  role          = aws_iam_role.sigv4_proxy_role.arn
  timeout       = 10

  environment {
    variables = {
      TARGET_URL = "${module.modernisation_platform_github.lambda_function_url}"
      REGION     = "eu-west-2"
      SERVICE    = "lambda"
    }
  }
}

resource "aws_lambda_function_url" "sigv4_proxy_url" {
  function_name      = aws_lambda_function.sigv4_proxy.function_name
  authorization_type = "AWS_IAM"
  cors {
    allow_origins     = ["https://${module.managed_grafana.workspace_id}.grafana-workspace.eu-west-2.amazonaws.com"]
    allow_methods     = ["POST", "GET", "OPTIONS"]
    allow_headers     = ["*"]
  }
}

resource "aws_lambda_permission" "allow_sigv4_url" {
  statement_id            = "AllowSigv4ToInvokeFunctionUrl"
  action                  = "lambda:InvokeFunctionUrl"
  function_name           = aws_lambda_function.sigv4_proxy.function_name
  principal               = "iam.amazonaws.com"
  function_url_auth_type  = "AWS_IAM"
  source_arn              = local.grafana_workspace_role_arn
}

# IAM Role & Policies

resource "aws_iam_role" "sigv4_proxy_role" {
  name = "sigv4-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement: [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "sigv4_proxy_permissions" {
  name = "AllowInvokeFunctionUrl"
  role = aws_iam_role.sigv4_proxy_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [{
      Effect = "Allow",
      Action = "lambda:InvokeFunctionUrl",
      Resource = "${module.modernisation_platform_github.lambda_function_arn}",
      Condition = {
        StringEquals = {
          "lambda:FunctionUrlAuthType" = "AWS_IAM"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "allow_ecr_pull" {
  name = "AllowCrossAccountECRPull"
  role = aws_iam_role.sigv4_proxy_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ],
        Resource = "arn:aws:ecr:eu-west-2:${local.environment_management.account_ids["core-shared-services-production"]}:repository/observability-platform-grafana-sigv4-proxy"
      }
    ]
  })
}