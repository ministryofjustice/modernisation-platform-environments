##############################################
### Lambda Function — User Creation via DS Data API
###
### Alternative to the EC2/PowerShell approach.
### Creates AD users directly via AWS Directory Service
### Data API (no EC2 dependency, no LDAP ports needed).
### Sends initial password via SES — never stored anywhere.
###
### Prerequisites:
###   - SES sending identity verified for SES_SENDER domain
###   - SES out of sandbox mode (or recipient emails verified)
###   - enable_directory_data_access = true on the directory (already set)
##############################################

data "archive_file" "user_creation_ds_lambda" {
  count = local.environment == "development" ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/xxx-new-scripts/user-creation-ds-lambda.zip"

  source {
    content  = file("${path.module}/xxx-new-scripts/user-creation-ds-lambda.py")
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "user_creation_ds" {
  count = local.environment == "development" ? 1 : 0

  function_name    = "${local.application_name}-${local.environment}-user-creation-ds"
  description      = "Creates AD users via DS Data API and sends credentials via SES — no EC2 dependency"
  filename         = data.archive_file.user_creation_ds_lambda[0].output_path
  source_code_hash = data.archive_file.user_creation_ds_lambda[0].output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 300
  memory_size      = 256
  role             = aws_iam_role.user_creation_ds_lambda_role[0].arn

  environment {
    variables = {
      DIRECTORY_ID        = aws_directory_service_directory.workspaces_ad[0].id
      WORKSPACE_BUNDLE_ID = local.workspace_types["standard"].bundle_id
      KMS_KEY_ID          = aws_kms_key.ebs[0].arn
      REGION              = local.application_data.accounts[local.environment].region
      SES_SENDER          = local.application_data.accounts[local.environment].ses_sender_email
    }
  }

  tags = merge(
    local.tags,
    {
      "Name"    = "${local.application_name}-${local.environment}-user-creation-ds-lambda"
      "Purpose" = "User creation via DS Data API with SES password delivery"
    }
  )
}

resource "aws_cloudwatch_log_group" "user_creation_ds_lambda" {
  count = local.environment == "development" ? 1 : 0

  name              = "/aws/lambda/${local.application_name}-${local.environment}-user-creation-ds"
  retention_in_days = 30

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-creation-ds-lambda-logs" }
  )
}

##############################################
### IAM Role for DS Lambda
##############################################

resource "aws_iam_role" "user_creation_ds_lambda_role" {
  count = local.environment == "development" ? 1 : 0

  name = "${local.application_name}-${local.environment}-user-creation-ds-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-creation-ds-lambda-role" }
  )
}

resource "aws_iam_role_policy_attachment" "user_creation_ds_lambda_basic" {
  count = local.environment == "development" ? 1 : 0

  role       = aws_iam_role.user_creation_ds_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "user_creation_ds_lambda_policy" {
  count = local.environment == "development" ? 1 : 0

  name = "${local.application_name}-${local.environment}-user-creation-ds-lambda-policy"
  role = aws_iam_role.user_creation_ds_lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DirectoryServiceDataAccess"
        Effect = "Allow"
        Action = ["ds:AccessDSData"]
        Resource = "arn:aws:ds:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:directory/${aws_directory_service_directory.workspaces_ad[0].id}"
      },
      {
        Sid    = "DirectoryServiceData"
        Effect = "Allow"
        Action = [
          "ds-data:CreateUser",
          "ds-data:DescribeUser",
          "ds-data:DeleteUser",
          "ds-data:ResetUserPassword"
        ]
        Resource = "arn:aws:ds:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:directory/${aws_directory_service_directory.workspaces_ad[0].id}"
      },
      {
        Sid      = "SESEmailDelivery"
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = "*"
      },
      {
        Sid    = "WorkSpacesCreate"
        Effect = "Allow"
        Action = [
          "workspaces:CreateWorkspaces",
          "workspaces:DescribeWorkspaces",
          "workspaces:CreateTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = ["kms:Decrypt", "kms:DescribeKey", "kms:CreateGrant", "kms:GenerateDataKey"]
        Resource = aws_kms_key.ebs[0].arn
      }
    ]
  })
}

##############################################
### Outputs
##############################################

output "user_creation_ds_lambda_function_name" {
  value       = local.environment == "development" ? aws_lambda_function.user_creation_ds[0].function_name : null
  description = "DS Data API Lambda function name"
}

output "user_creation_ds_invoke_command" {
  value = local.environment == "development" ? "aws lambda invoke --function-name ${aws_lambda_function.user_creation_ds[0].function_name} --payload '{\"Firstname\":\"Bob\",\"Lastname\":\"Smith\",\"Email\":\"bob.smith@justice.gov.uk\"}' --region ${local.application_data.accounts[local.environment].region} output.txt --cli-binary-format raw-in-base64-out --cli-read-timeout 0" : null
  description = "Example command to invoke DS API user creation Lambda"
}
