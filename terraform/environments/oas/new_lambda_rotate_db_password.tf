######################################
### Manual RDS Master Password Rotation Lambda
###
### Invoked manually (console "Test" or `aws lambda invoke`) — not wired
### to Secrets Manager automatic rotation, so no rotation schedule or
### EventBridge rule is created.
######################################

data "archive_file" "rotate_db_password_lambda_zip" {
  count       = contains(["preproduction", "development"], local.environment) ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambda/rotate_db_master_password/lambda_function.py"
  output_path = "${path.module}/lambda/rotate_db_master_password/lambda_function.zip"
}

resource "aws_lambda_function" "rotate_db_master_password" {
  count            = contains(["preproduction", "development"], local.environment) ? 1 : 0
  description      = "Manually-invoked rotation of the OAS RDS master password."
  function_name    = "oas-rotate-db-master-password-${local.environment}"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.rotate_db_password_lambda_role[0].arn
  filename         = data.archive_file.rotate_db_password_lambda_zip[0].output_path
  source_code_hash = data.archive_file.rotate_db_password_lambda_zip[0].output_base64sha256
  timeout          = 60

  environment {
    variables = {
      DB_INSTANCE_IDENTIFIER = aws_db_instance.oas_rds_instance[0].identifier
      SECRET_ID              = aws_secretsmanager_secret.rds_password_secret_new[0].id
    }
  }

  tags = merge(
    local.tags,
    { Name = "oas-${local.environment}-rotate-db-master-password" }
  )
}

######################################
### IAM Resources
######################################

resource "aws_iam_role" "rotate_db_password_lambda_role" {
  count = contains(["preproduction", "development"], local.environment) ? 1 : 0
  name  = "oas-rotate-db-password-lambda-role-${local.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    { Name = "oas-${local.environment}-rotate-db-password-lambda-role" }
  )
}

resource "aws_iam_policy" "rotate_db_password_lambda_policy" {
  count = contains(["preproduction", "development"], local.environment) ? 1 : 0
  name  = "oas-rotate-db-password-lambda-policy-${local.environment}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.rds_password_secret_new[0].arn
        ]
      },
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetRandomPassword"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:ModifyDBInstance"
        ]
        Resource = [
          aws_db_instance.oas_rds_instance[0].arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/oas-rotate-db-master-password-${local.environment}:*"
      }
    ]
  })

  tags = merge(
    local.tags,
    { Name = "oas-${local.environment}-rotate-db-password-lambda-policy" }
  )
}

resource "aws_iam_role_policy_attachment" "rotate_db_password_lambda_policy_attach" {
  count      = contains(["preproduction", "development"], local.environment) ? 1 : 0
  role       = aws_iam_role.rotate_db_password_lambda_role[0].name
  policy_arn = aws_iam_policy.rotate_db_password_lambda_policy[0].arn
}
