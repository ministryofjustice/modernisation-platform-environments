# ##################################
# ### AWS SECRETS MANAGER SECRETS ####
# ##################################


# ######## db secret

resource "random_string" "db-master-pass-string" {
  length  = 32 # as per rotated string
  special = true
}

resource "aws_secretsmanager_secret" "db-master-password" {
  name        = "${local.application_name}/app/db-master-password"
  description = "EDW DB EC2 Root Password"

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-db-master-password-"
    }
  )
}

resource "aws_secretsmanager_secret_version" "edw_db_master_password_version" {
  secret_id     = aws_secretsmanager_secret.db-master-password.id
  secret_string = random_string.db-master-pass-string.result
}


######## db ec2 root secret

resource "random_string" "edw-root-secret_id_suffix" {
  length  = local.application_data.accounts[local.environment].secret_id_suffix_length
  special = false
}

resource "random_string" "edw-initial_root_secret_value" {
  length  = 32 # as per rotated string
  special = true
}

resource "aws_secretsmanager_secret" "edw_db_ec2_root_secret" {
  name        = "${local.application_name}/app/db-EC2-root-password-${random_string.edw-root-secret_id_suffix.result}"
  description = "EDW DB EC2 Root Password"

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-system-root-password"
    }
  )
}

resource "aws_secretsmanager_secret_version" "edw_db_ec2_root_password_version" {
  secret_id     = aws_secretsmanager_secret.edw_db_ec2_root_secret.id
  secret_string = random_string.edw-initial_root_secret_value.result
}

resource "aws_secretsmanager_secret_rotation" "edw_db_root_rotate" {
  secret_id           = aws_secretsmanager_secret.edw_db_ec2_root_secret.id
  rotation_lambda_arn = aws_lambda_function.rotate_secret_function.arn
  rotate_immediately  = true

  rotation_rules {
    automatically_after_days = local.application_data.accounts[local.environment].secret_rotation_frequency_days
  }
}


# ##########################
# ## AWS LAMBDA FUNCTION ###
# ##########################

data "archive_file" "lambda_inline_code" {
  type        = "zip"
  output_path = replace(local.application_data.accounts[local.environment].lambda_function_inline_code_filename, "py", "zip")

  source {
    filename = local.application_data.accounts[local.environment].lambda_function_inline_code_filename
    content  = file("${local.application_data.accounts[local.environment].lambda_function_inline_code_filename}")
  }
}

resource "aws_lambda_function" "rotate_secret_function" {
  function_name = local.application_data.accounts[local.environment].lambda_function_name
  description   = local.application_data.accounts[local.environment].lambda_function_description
  role          = aws_iam_role.edw_lambda_function_execution_role.arn
  handler       = local.application_data.accounts[local.environment].lambda_function_handler
  runtime       = local.application_data.accounts[local.environment].lambda_function_runtime
  timeout       = local.application_data.accounts[local.environment].lambda_function_timeout

  filename         = data.archive_file.lambda_inline_code.output_path
  source_code_hash = data.archive_file.lambda_inline_code.output_base64sha256 # hash ensures that changes to inline code are always picked up by a plan/apply

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.eu-west-2.amazonaws.com"
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-edw-secret-rotate-function"
    }
  )
}

resource "aws_iam_role" "edw_lambda_function_execution_role" {
  name = "${local.application_data.accounts[local.environment].lambda_function_name}-execution-role"

  assume_role_policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Effect : "Allow"
        Principal : {
          Service : "lambda.amazonaws.com"
        },
        Action : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "edw_lambda_function_execution_role_policy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${local.application_data.accounts[local.environment].lambda_function_name}-Policy"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-edw-secret-rotate-function"
    }
  )
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
        ],
        Resource = [
          "arn:aws:logs:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:*",
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Resource = [
          "arn:aws:logs:${local.application_data.accounts[local.environment].edw_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.application_data.accounts[local.environment].lambda_function_name}:*",
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:ListSecrets",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
          "secretsmanager:GetRandomPassword",
          "lambda:InvokeFunction",
        ],
        Resource = "*"
      },
      {
        Sid    = "GenerateARandomStringToExecuteRotation",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetRandomPassword",
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  role       = aws_iam_role.edw_lambda_function_execution_role.name
  policy_arn = aws_iam_policy.edw_lambda_function_execution_role_policy.arn
}


resource "aws_lambda_permission" "rotate_secret_function_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_secret_function.function_name
  principal     = "secretsmanager.amazonaws.com"
}