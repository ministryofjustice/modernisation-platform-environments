# TODO this part of the implementation rotates a value in aws secrets manager only.
# successful rotation of the system's root password is thereafter dependant on the
# following task being added to cron, as implemented in laa landing zone's edw:
#
# 0 6 28 * * /root/scripts/rootrotate.sh
# [root@EDW ~]# cat /root/scripts/rootrotate.sh
# export SECRET2=`/usr/local/bin/aws --region eu-west-2 secretsmanager get-secret-value --secret-id EDW/app/db-EC2-root-password --query SecretString --output text`
# echo "$SECRET2" | passwd root --stdin
#
# See LAWS-2902 for jira tasks relating to the revision of this component


# for reasoning behind deployment strategy of lambda function, refer to:
# https://mojdt.slack.com/archives/C01A7QK5VM1/p1671441837036929

locals {
  lambda_function_name = "${var.application_name}-${var.lambda_function_name}"
}

##################################
### AWS SECRETS MANAGER SECRET ###
##################################
resource "aws_secretsmanager_secret" "system_root_password" {
  name        = "${var.application_name}/app/system-root-password"
  description = "This secret has a dynamically generated password."

  recovery_window_in_days        = 0
  force_overwrite_replica_secret = true

  tags = var.tags
}

resource "aws_secretsmanager_secret_rotation" "system_root_password_rotation" {
  secret_id           = aws_secretsmanager_secret.system_root_password.id
  rotation_lambda_arn = aws_lambda_function.rotate_secret_function.arn

  rotation_rules {
    automatically_after_days = var.secret_rotation_frequency_days
  }
}

###########################
### AWS LAMBDA FUNCTION ###
###########################
data "archive_file" "lambda_inline_code" {
  type        = "zip"
  output_path = "${path.module}/${var.zip_artefact_filename}"

  source {
    filename = var.lambda_function_inline_code_filename
    content  = file("${path.module}/${var.lambda_function_inline_code_filename}")
  }
}

resource "aws_lambda_function" "rotate_secret_function" {
  function_name = local.lambda_function_name
  description   = var.lambda_function_description
  role          = aws_iam_role.lambda_function_execution_role.arn
  handler       = var.lambda_function_handler
  runtime       = var.lambda_function_runtime
  timeout       = var.lambda_function_timeout

  filename         = data.archive_file.lambda_inline_code.output_path
  source_code_hash = data.archive_file.lambda_inline_code.output_base64sha256

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.eu-west-2.amazonaws.com"
    }
  }

  tags = var.tags
}

resource "aws_iam_role" "lambda_function_execution_role" {
  name = "${local.lambda_function_name}-execution-role"

  assume_role_policy = file("${path.module}/assume-role-policy.json")

  inline_policy {
    name = "${local.lambda_function_name}-execution-policy"

    policy = templatefile("${path.module}/lambda-execution-policy.json", {
      AWS_ACCOUNT_ID = var.aws_account_id
      FUNCTION_NAME  = local.lambda_function_name
    })
  }

  tags = var.tags
}

resource "aws_lambda_permission" "rotate_secret_function_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_secret_function.function_name
  principal     = "secretsmanager.amazonaws.com"
}
