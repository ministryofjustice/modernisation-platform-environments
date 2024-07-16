resource "aws_iam_role" "lambda_role" {
  name = "lambda_db_setup_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "random_password" "app_new_password" {
  length  = 16
  special = false
}

# resource "aws_lambda_function" "app_setup_db" {
#   for_each      = var.web_app_services
#   filename      = "lambda_function/my-deployment-package.zip"
#   function_name = "${each.value.name_prefix}-setup-db"
#   role          = aws_iam_role.lambda_role.arn
#   handler       = "index.handler"
#   runtime       = "python3.8"
#   timeout       = 300

#   environment {
#     variables = {
#       DB_URL        = aws_db_instance.rdsdb.address
#       USER_NAME     = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
#       PASSWORD      = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
#       NEW_DB_NAME   = each.value.app_db_name
#       NEW_USER_NAME = each.value.app_db_login_name
#       NEW_PASSWORD  = random_password.app_new_password.result
#       APP_FOLDER    = each.value.sql_migration_path
#     }
#   }
# }

# resource "null_resource" "app_setup_db" {
#   for_each = aws_lambda_function.app_setup_db

#   provisioner "local-exec" {
#     command = <<-EOT
#       aws lambda invoke \
#         --function-name ${each.value.function_name} \
#         --payload '{}' \
#         response.json
#     EOT
#   }

#   triggers = {
#     always_run = "${timestamp()}"
#   }
# }
