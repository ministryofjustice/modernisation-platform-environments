locals {
  target_function_url = module.modernisation_platform_github.lambda_function_url
  allowed_methods = [
      trimspace("GET"),
      trimspace("OPTIONS"),
      trimspace("POST")
    ]
}


# Secrets

#tfsec:ignore:avd-aws-0098 CMK not required currently
resource "aws_secretsmanager_secret" "modernisation_platform_github_pat" {
  #checkov:skip=CKV_AWS_149:CMK not required currently
  #checkov:skip=CKV2_AWS_57:Rotation of secrets not required currently

  name = "observability-platform/modernisation-platform-github-pat"
}

#tfsec:ignore:avd-aws-0098 CMK not required currently
resource "aws_secretsmanager_secret" "modernisation_platform_sigv4_token" {
  #checkov:skip=CKV_AWS_149:CMK not required currently
  #checkov:skip=CKV2_AWS_57:Rotation of secrets not required currently

  name = "observability-platform/modernisation-platform-sigv4-token"
}


#################################################
# Lambda Function for GitHub Workflow Data
#################################################

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

resource "aws_lambda_permission" "allow_sigv4_proxy_to_invoke" {
  statement_id            = "AllowSigv4ProxyInvoke"
  action                  = "lambda:InvokeFunctionUrl"
  function_name           = module.modernisation_platform_github.lambda_function_name
  principal               = "iam.amazonaws.com"
  function_url_auth_type  = "AWS_IAM"
  source_arn              = aws_iam_role.sigv4_proxy_role.arn
}


# IAM Resource for Github Workflows Lambda Function

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "grafana.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
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
    # condition {
    #   test     = "StringEquals"
    #   variable = "lambda:FunctionUrlAuthType"
    #   values   = ["AWS_IAM"]
    # }
  }
  statement {
    sid     = "AllowAssumeLambdaRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      aws_iam_role.lambda_exec.arn
    ]
  }
}

resource "aws_iam_policy" "grafana_lambda_policy" {
  name   = "grafana-invoke-lambda-url"
  policy = data.aws_iam_policy_document.grafana_lambda_invoke.json
}


#################################################
# AWS SigV4 Proxy Lambda Function
#################################################


resource "aws_lambda_function" "sigv4_proxy" {
  function_name = "sigv4-proxy"
  package_type  = "Image"
  image_uri     = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/observability-platform-grafana-sigv4-proxy:latest"
  role          = aws_iam_role.sigv4_proxy_role.arn
  timeout       = 10

  environment {
    variables = {
      GRAFANA_PROXY_API_KEY = "/aws/reference/secretsmanager/observability-platform/modernisation_platform_sigv4_token:token"
      TARGET_URL = "https://el7n7n7d4he7eqp7ahjs64nk440ygztq.lambda-url.eu-west-2.on.aws/"
      REGION     = "eu-west-2"
      SERVICE    = "lambda"
    }
  }
}

resource "aws_lambda_function_url" "sigv4_proxy_url" {
  function_name      = aws_lambda_function.sigv4_proxy.function_name
  authorization_type = "NONE"
  cors {
    allow_origins     = ["https://${module.managed_grafana.workspace_id}.grafana-workspace.eu-west-2.amazonaws.com"]
    allow_methods = [
      "GET",
      "POST",
      "OPTIONS"
    ]    
    allow_headers     = ["*"]
  }
}

resource "aws_lambda_permission" "allow_sigv4_url" {
  statement_id            = "AllowSigv4ToInvokeFunctionUrl"
  action                  = "lambda:InvokeFunctionUrl"
  function_name           = aws_lambda_function.sigv4_proxy.function_name
  principal               = "iam.amazonaws.com"
  source_arn              = module.managed_grafana.workspace_iam_role_arn
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

resource "aws_iam_role_policy_attachment" "sigv4_lambda_exec_policy" {
  role       = aws_iam_role.sigv4_proxy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "allow_sigv4_secret" {
  name = "AllowSigv4SecretAccess"
  role = aws_iam_role.sigv4_proxy_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = "${aws_secretsmanager_secret.modernisation_platform_sigv4_token.arn}"
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

# Outputs

output "lambda_function_url" {
  value = module.modernisation_platform_github.lambda_function_url
}