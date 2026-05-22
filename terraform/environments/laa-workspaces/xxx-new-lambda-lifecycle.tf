##############################################
### Lambda Function — User Lifecycle Management
###
### Triggered by EventBridge when user list secret is updated.
### Compares current vs previous secret version and
### creates or deletes users accordingly.
##############################################

data "archive_file" "user_lifecycle_lambda" {
  count = local.environment == "development" ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/xxx-new-scripts/user-lifecycle-lambda.zip"

  source {
    content  = file("${path.module}/xxx-new-scripts/user-lifecycle-lambda.py")
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "user_lifecycle" {
  count = local.environment == "development" ? 1 : 0

  function_name    = "${local.application_name}-${local.environment}-user-lifecycle"
  description      = "Processes user list secret changes to create or delete AD users and WorkSpaces"
  filename         = data.archive_file.user_lifecycle_lambda[0].output_path
  source_code_hash = data.archive_file.user_lifecycle_lambda[0].output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 900
  memory_size      = 512
  role             = aws_iam_role.user_lifecycle_lambda_role[0].arn

  environment {
    variables = {
      DIRECTORY_ID         = aws_directory_service_directory.workspaces_ad[0].id
      REGION               = local.application_data.accounts[local.environment].region
      USER_CREATION_LAMBDA = aws_lambda_function.user_creation[0].function_name
      ALLOW_MASS_DELETE    = "false"
      DRY_RUN              = "false"
    }
  }

  tags = merge(
    local.tags,
    {
      "Name"    = "${local.application_name}-${local.environment}-user-lifecycle-lambda"
      "Purpose" = "Declarative user lifecycle management"
    }
  )

  depends_on = [
    aws_lambda_function.user_creation,
    aws_iam_role.user_lifecycle_lambda_role
  ]
}

resource "aws_cloudwatch_log_group" "user_lifecycle_lambda" {
  count = local.environment == "development" ? 1 : 0

  name              = "/aws/lambda/${local.application_name}-${local.environment}-user-lifecycle"
  retention_in_days = 30

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-lifecycle-lambda-logs" }
  )
}

##############################################
### IAM Role for User Lifecycle Lambda
##############################################

resource "aws_iam_role" "user_lifecycle_lambda_role" {
  count = local.environment == "development" ? 1 : 0

  name = "${local.application_name}-${local.environment}-user-lifecycle-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-lifecycle-lambda-role" }
  )
}

resource "aws_iam_role_policy_attachment" "user_lifecycle_lambda_basic" {
  count = local.environment == "development" ? 1 : 0

  role       = aws_iam_role.user_lifecycle_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "user_lifecycle_lambda_policy" {
  count = local.environment == "development" ? 1 : 0

  name = "${local.application_name}-${local.environment}-user-lifecycle-lambda-policy"
  role = aws_iam_role.user_lifecycle_lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerUserList"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.user_list[0].arn
      },
      {
        Sid    = "InvokeUserCreationLambda"
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = aws_lambda_function.user_creation[0].arn
      },
      {
        Sid    = "WorkSpacesManagement"
        Effect = "Allow"
        Action = [
          "workspaces:DescribeWorkspaces",
          "workspaces:TerminateWorkspaces"
        ]
        Resource = "*"
      },
      {
        Sid    = "DirectoryServiceDataDelete"
        Effect = "Allow"
        Action = [
          "ds-data:DeleteUser",
          "ds-data:DescribeUser"
        ]
        Resource = "arn:aws:ds:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:directory/${aws_directory_service_directory.workspaces_ad[0].id}"
      },
      {
        Sid    = "SSMParameterCleanup"
        Effect = "Allow"
        Action = ["ssm:DeleteParameter"]
        Resource = "arn:aws:ssm:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:parameter/laa-workspaces/${local.environment}/user-passwords/*"
      },
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.ebs[0].arn
      }
    ]
  })
}

##############################################
### Outputs
##############################################

output "user_lifecycle_lambda_function_name" {
  value       = local.environment == "development" ? aws_lambda_function.user_lifecycle[0].function_name : null
  description = "Lambda function name for user lifecycle management"
}
