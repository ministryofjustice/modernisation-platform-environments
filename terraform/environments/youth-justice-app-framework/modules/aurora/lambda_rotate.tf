locals {
  user_admin_secret_arns = values(aws_secretsmanager_secret.user_admin_secret)[*].arn
}

resource "aws_lambda_function" "rds_secret_rotation" {
  #checkov:skip=CKV_AWS_50: "X-ray tracing is not required"
  #checkov:skip=CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing"#checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  #checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  #checkov:skip=CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit"
  #checkov:skip=CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)"
  #checkov:skip=CKV_AWS_363: "fix before deprecation date"
  function_name = "rds-secrets-rotation"
  role          = aws_iam_role.rds_secret_rotation.arn
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"
  timeout       = 30
  memory_size   = 128
  filename      = "${path.module}/zip/rotation_lambda.zip"
  kms_key_arn   = var.kms_key_arn

  environment {
    variables = {
      EXCLUDE_CHARACTERS       = ":/@'\\\"",
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.eu-west-2.amazonaws.com"
    }
  }

  tags = local.all_tags
}

#Iam bits for lambda rotation
resource "aws_iam_role" "rds_secret_rotation" {
  name = "rds-secret-rotation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_secret_rotation_secrets_policy" {
  role       = aws_iam_role.rds_secret_rotation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "rds_secret_rotation_secrets_policy_VPC" {
  role       = aws_iam_role.rds_secret_rotation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "rds_secret_rotation_policy" {
  #checkov:skip=CKV_AWS_356: get random password is required for the lambda to rotate the secret
  name        = "rds-secret-rotation-policy"
  description = "Allows Lambda to rotate RDS credentials"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Condition" : {
          "StringEquals" : {
            "secretsmanager:resource/AllowRotationLambdaArn" : aws_lambda_function.rds_secret_rotation.arn
          }
        },
        "Action" : [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ],
        "Resource" : local.user_admin_secret_arns,
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "secretsmanager:GetRandomPassword"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        "Resource" : var.kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_secret_rotation_policy_attach_custom" {
  role       = aws_iam_role.rds_secret_rotation.name
  policy_arn = aws_iam_policy.rds_secret_rotation_policy.arn
}


resource "aws_lambda_permission" "allow_secrets_manager" {
  for_each = toset(var.user_passwords_to_reset_rotated)

  statement_id_prefix = "AllowSecretsManagerInvoke-${each.value}"
  action              = "lambda:InvokeFunction"
  function_name       = aws_lambda_function.rds_secret_rotation.function_name
  principal           = "secretsmanager.amazonaws.com"

  # Restrict invocation to a specific AWS account
  source_arn = aws_secretsmanager_secret.user_admin_secret[each.value].arn


}
