##################################
### AWS SECRETS MANAGER SECRETS ###
##################################

resource "aws_secretsmanager_secret" "edw_db_secret" {
  name        = "${local.application_name}/app/db-master-password"
  description = "EDW DB Password"
}

resource "aws_secretsmanager_secret" "edw_db_ec2_root_secret" {
  name        = "${local.application_name}/app/db-EC2-root-password"
  description = "EDW DB EC2 Root Password"
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = aws_secretsmanager_secret.edw_db_secret.id
}

output "edw_db_secret" {
  value = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["db-master-password"]
}

resource "aws_secretsmanager_secret_rotation" "edw_db_root_rotate" {
  secret_id                  = aws_secretsmanager_secret.edw_db_ec2_root_secret.id
  rotation_lambda_arn        = aws_lambda_function.rotate_secret_function.arn
  rotate_immediately = true
  rotation_rules {
    automatically_after_days = local.application_data.accounts[local.environment].secret_rotation_frequency_days
  }
}

###########################
### AWS LAMBDA FUNCTION ###
###########################

data "archive_file" "lambda_inline_code" {
  type        = "zip"
  output_path = "${replace(local.application_data.accounts[local.environment].lambda_function_inline_code_filename, "py", "zip")}"

  source {
    filename = local.application_data.accounts[local.environment].lambda_function_inline_code_filename
    content  = file("${local.application_data.accounts[local.environment].lambda_function_inline_code_filename}")
  }
}

resource "aws_lambda_function" "rotate_secret_function" {
  function_name = local.application_data.accounts[local.environment].lambda_function_name
  description   = local.application_data.accounts[local.environment].lambda_function_description
  role          = aws_iam_role.lambda_function_execution_role.arn
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

resource "aws_iam_role" "lambda_function_execution_role" {
  name = "${local.application_data.accounts[local.environment].lambda_function_name}-execution-role"

  assume_role_policy = jsonencode({
    Version: "2008-10-17"
    Statement: [
        {
        Effect: "Allow"
        Principal: {
            Service: "lambda.amazonaws.com"
        },
        Action: "sts:AssumeRole"
        }
    ]
  })
  
  inline_policy {
    name = "${local.application_data.accounts[local.environment].lambda_function_name}-execution-policy"

    policy = templatefile("lambda-execution-policy.json", {
      AWS_ACCOUNT_ID = local.application_data.accounts[local.environment].aws_account_id
      FUNCTION_NAME  = local.application_data.accounts[local.environment].lambda_function_name
    })
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-edw-lambda-execution-role"
    }
  ) 
}

resource "aws_lambda_permission" "rotate_secret_function_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_secret_function.function_name
  principal     = "secretsmanager.amazonaws.com"
}