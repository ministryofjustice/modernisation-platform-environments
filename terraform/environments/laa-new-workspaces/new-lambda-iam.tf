##############################################
### IAM Role for Lambda User Creation Function
##############################################

resource "aws_iam_role" "user_creation_lambda_role" {

  name = "${local.application_name}-${local.environment}-user-creation-lambda-role"

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
    { "Name" = "${local.application_name}-${local.environment}-user-creation-lambda-role" }
  )
}

# Attach AWS managed policies
resource "aws_iam_role_policy_attachment" "user_creation_lambda_basic" {

  role       = aws_iam_role.user_creation_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for SSM and WorkSpaces
resource "aws_iam_role_policy" "user_creation_lambda_policy" {

  name = "${local.application_name}-${local.environment}-user-creation-lambda-policy"
  role = aws_iam_role.user_creation_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMSendCommand"
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations"
        ]
        Resource = [
          "arn:aws:ec2:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ssm:${local.application_data.accounts[local.environment].region}::document/AWS-RunPowerShellScript",
          "arn:aws:ssm:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:*"
        ]
      },
      {
        Sid    = "WorkSpacesManagement"
        Effect = "Allow"
        Action = [
          "workspaces:CreateWorkspaces",
          "workspaces:DescribeWorkspaces",
          "workspaces:DescribeWorkspaceDirectories",
          "workspaces:CreateTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:secret:${local.application_name}/${local.environment}/user-passwords/*"
      },
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.ebs.arn
      },
      {
        Sid      = "SESEmailDelivery"
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = "*"
      }
    ]
  })
}

##############################################
### IAM Role for User Lifecycle Lambda
##############################################

resource "aws_iam_role" "user_lifecycle_lambda_role" {

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

  role       = aws_iam_role.user_lifecycle_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "user_lifecycle_lambda_policy" {

  name = "${local.application_name}-${local.environment}-user-lifecycle-lambda-policy"
  role = aws_iam_role.user_lifecycle_lambda_role.id

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
        Resource = aws_secretsmanager_secret.user_list.arn
      },
      {
        Sid      = "InvokeUserCreationLambda"
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = aws_lambda_function.user_creation.arn
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
        Sid      = "DirectoryServiceDataAccess"
        Effect   = "Allow"
        Action   = ["ds:AccessDSData"]
        Resource = "arn:aws:ds:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:directory/${aws_directory_service_directory.workspaces_ad.id}"
      },
      {
        Sid    = "DirectoryServiceDataDelete"
        Effect = "Allow"
        Action = [
          "ds-data:DeleteUser",
          "ds-data:DescribeUser"
        ]
        Resource = "arn:aws:ds:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:directory/${aws_directory_service_directory.workspaces_ad.id}"
      },
      {
        Sid      = "SSMParameterCleanup"
        Effect   = "Allow"
        Action   = ["ssm:DeleteParameter"]
        Resource = "arn:aws:ssm:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:parameter/laa-workspaces/${local.environment}/user-passwords/*"
      },
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.ebs.arn
      }
    ]
  })
}