##############################################
### Lambda Function for User Creation
### 
### Invokes PowerShell script on EC2 to create AD user
### and creates WorkSpace for the user
##############################################

# Create Lambda deployment package
data "archive_file" "user_creation_lambda" {

  type        = "zip"
  output_path = "${path.module}/scripts/user-creation-lambda.zip"

  source {
    content  = file("${path.module}/scripts/user-creation-lambda.py")
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "user_creation" {

  function_name    = "${local.application_name}-${local.environment}-user-creation"
  description      = "Creates AD users and WorkSpaces via PowerShell on EC2"
  filename         = data.archive_file.user_creation_lambda.output_path
  source_code_hash = data.archive_file.user_creation_lambda.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 900
  memory_size      = 512
  role             = aws_iam_role.user_creation_lambda_role.arn

  environment {
    variables = {
      # Must point to Windows EC2 instance for domain-joined PowerShell execution
      EC2_INSTANCE_ID       = aws_instance.user_creation_ec2.id
      DIRECTORY_ID          = aws_directory_service_directory.workspaces_ad.id
      BUNDLE_ID_STANDARD    = local.workspace_types["standard"].bundle_id
      BUNDLE_ID_PERFORMANCE = local.workspace_types["performance"].bundle_id
      BUNDLE_ID_POWER       = local.workspace_types["power"].bundle_id
      KMS_KEY_ID            = aws_kms_key.ebs.arn
      REGION                = local.application_data.accounts[local.environment].region
      SES_SENDER            = data.terraform_remote_state.workspace_components.outputs.ses_sender_email
      SELFSERVICE_URL       = "${data.terraform_remote_state.workspace_components.outputs.radius_portal_url}/selfservice/login"
    }
  }

  tags = merge(
    local.tags,
    {
      "Name"        = "${local.application_name}-${local.environment}-user-creation-lambda"
      "Purpose"     = "User and WorkSpace creation automation"
      "EC2Instance" = aws_instance.user_creation_ec2.id # Tag to track dependency
    }
  )

  depends_on = [
    aws_instance.user_creation_ec2,
    terraform_data.lambda_service_account,
    aws_ssm_parameter.lambda_service_account_password
  ]
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "user_creation_lambda" {

  name              = "/aws/lambda/${local.application_name}-${local.environment}-user-creation"
  retention_in_days = 30

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-creation-lambda-logs" }
  )
}

##############################################
### Lambda Function — User Lifecycle Management
###
### Triggered by EventBridge when user list secret is updated.
### Compares current vs previous secret version and
### creates or deletes users accordingly.
##############################################

data "archive_file" "user_lifecycle_lambda" {

  type        = "zip"
  output_path = "${path.module}/scripts/user-lifecycle-lambda.zip"

  source {
    content  = file("${path.module}/scripts/user-lifecycle-lambda.py")
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "user_lifecycle" {

  function_name    = "${local.application_name}-${local.environment}-user-lifecycle"
  description      = "Processes user list secret changes to create or delete AD users and WorkSpaces"
  filename         = data.archive_file.user_lifecycle_lambda.output_path
  source_code_hash = data.archive_file.user_lifecycle_lambda.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 900
  memory_size      = 512
  role             = aws_iam_role.user_lifecycle_lambda_role.arn

  environment {
    variables = {
      DIRECTORY_ID         = aws_directory_service_directory.workspaces_ad.id
      REGION               = local.application_data.accounts[local.environment].region
      USER_CREATION_LAMBDA = aws_lambda_function.user_creation.function_name
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

  name              = "/aws/lambda/${local.application_name}-${local.environment}-user-lifecycle"
  retention_in_days = 30

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-lifecycle-lambda-logs" }
  )
}

##############################################
### Outputs
##############################################

output "user_creation_lambda_function_name" {
  value       = local.environment == "development" ? aws_lambda_function.user_creation.function_name : null
  description = "Lambda function name for user creation"
}

output "user_creation_lambda_arn" {
  value       = local.environment == "development" ? aws_lambda_function.user_creation.arn : null
  description = "Lambda function ARN for user creation"
}

output "user_creation_invoke_command" {
  value       = local.environment == "development" ? "aws lambda invoke --function-name ${aws_lambda_function.user_creation.function_name} --payload '{\"Firstname\":\"John\",\"Lastname\":\"Doe\",\"Email\":\"john.doe@justice.gov.uk\"}' --region ${local.application_data.accounts[local.environment].region} output.txt --cli-binary-format raw-in-base64-out" : null
  description = "Example command to invoke user creation Lambda"
}

output "user_lifecycle_lambda_function_name" {
  value       = local.environment == "development" ? aws_lambda_function.user_lifecycle.function_name : null
  description = "Lambda function name for user lifecycle management"
}
