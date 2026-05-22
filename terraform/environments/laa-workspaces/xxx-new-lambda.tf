##############################################
### Lambda Function for User Creation
### 
### Invokes PowerShell script on EC2 to create AD user
### and creates WorkSpace for the user
##############################################

# Create Lambda deployment package
data "archive_file" "user_creation_lambda" {
  count = local.environment == "development" ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/xxx-new-scripts/user-creation-lambda.zip"

  source {
    content  = file("${path.module}/xxx-new-scripts/user-creation-lambda.py")
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "user_creation" {
  count = local.environment == "development" ? 1 : 0

  function_name    = "${local.application_name}-${local.environment}-user-creation"
  description      = "Creates AD users and WorkSpaces via PowerShell on EC2"
  filename         = data.archive_file.user_creation_lambda[0].output_path
  source_code_hash = data.archive_file.user_creation_lambda[0].output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 900
  memory_size      = 512
  role             = aws_iam_role.user_creation_lambda_role[0].arn

  environment {
    variables = {
      # Must point to Windows EC2 instance for domain-joined PowerShell execution
      EC2_INSTANCE_ID     = aws_instance.user_creation_ec2[0].id
      DIRECTORY_ID        = aws_directory_service_directory.workspaces_ad[0].id
      WORKSPACE_BUNDLE_ID = local.workspace_types["standard"].bundle_id
      KMS_KEY_ID          = aws_kms_key.ebs[0].arn
      REGION              = local.application_data.accounts[local.environment].region
      SES_SENDER          = data.terraform_remote_state.workspace_components.outputs.ses_sender_email
    }
  }

  tags = merge(
    local.tags,
    {
      "Name"        = "${local.application_name}-${local.environment}-user-creation-lambda"
      "Purpose"     = "User and WorkSpace creation automation"
      "EC2Instance" = aws_instance.user_creation_ec2[0].id # Tag to track dependency
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
  count = local.environment == "development" ? 1 : 0

  name              = "/aws/lambda/${local.application_name}-${local.environment}-user-creation"
  retention_in_days = 30

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-creation-lambda-logs" }
  )
}

##############################################
### Outputs
##############################################

output "user_creation_lambda_function_name" {
  value       = local.environment == "development" ? aws_lambda_function.user_creation[0].function_name : null
  description = "Lambda function name for user creation"
}

output "user_creation_lambda_arn" {
  value       = local.environment == "development" ? aws_lambda_function.user_creation[0].arn : null
  description = "Lambda function ARN for user creation"
}

output "user_creation_invoke_command" {
  value       = local.environment == "development" ? "aws lambda invoke --function-name ${aws_lambda_function.user_creation[0].function_name} --payload '{\"Firstname\":\"John\",\"Lastname\":\"Doe\",\"Email\":\"john.doe@justice.gov.uk\"}' --region ${local.application_data.accounts[local.environment].region} output.txt --cli-binary-format raw-in-base64-out" : null
  description = "Example command to invoke user creation Lambda"
}
