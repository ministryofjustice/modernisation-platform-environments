##############################################
### IAM Role for EC2 User Creation Instance
##############################################

resource "aws_iam_role" "user_creation_ec2_role" {
  count = local.environment == "development" ? 1 : 0

  name = "${local.application_name}-${local.environment}-user-creation-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-creation-ec2-role" }
  )
}

resource "aws_iam_role_policy_attachment" "user_creation_ec2_ssm_managed" {
  count = local.environment == "development" ? 1 : 0

  role       = aws_iam_role.user_creation_ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "user_creation_ec2_directory_service" {
  count = local.environment == "development" ? 1 : 0

  role       = aws_iam_role.user_creation_ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
}

# Allow EC2 to read SSM parameters (for service account password and user passwords)
resource "aws_iam_role_policy" "user_creation_ec2_ssm_parameters" {
  count = local.environment == "development" ? 1 : 0

  name = "${local.application_name}-${local.environment}-user-creation-ec2-ssm-params"
  role = aws_iam_role.user_creation_ec2_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:PutParameter"
        ]
        Resource = [
          "arn:aws:ssm:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:parameter/laa-workspaces/${local.environment}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "user_creation_ec2_profile" {
  count = local.environment == "development" ? 1 : 0

  name = "${local.application_name}-${local.environment}-user-creation-ec2-profile"
  role = aws_iam_role.user_creation_ec2_role[0].name

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-creation-ec2-profile" }
  )
}

##############################################
### IAM Role for Lambda User Creation Function
##############################################

resource "aws_iam_role" "user_creation_lambda_role" {
  count = local.environment == "development" ? 1 : 0

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
  count = local.environment == "development" ? 1 : 0

  role       = aws_iam_role.user_creation_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for SSM and WorkSpaces
resource "aws_iam_role_policy" "user_creation_lambda_policy" {
  count = local.environment == "development" ? 1 : 0

  name = "${local.application_name}-${local.environment}-user-creation-lambda-policy"
  role = aws_iam_role.user_creation_lambda_role[0].id

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
        Sid    = "KMSDecrypt"
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
