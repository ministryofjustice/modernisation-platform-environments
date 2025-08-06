# resource "aws_lambda_function" "ccms_lambda" {
#   filename         = "lambda/ccms_lambda/ccms_lambda.zip"
#   function_name    = "ccms_lambda_function"
#   role            = aws_iam_role.ccms_lambda_role.arn
#   handler          = "ccms_lambda_function.lambda_handler"
#   runtime          = "python3.10"
#   source_code_hash = filebase64sha256("lambda/ccms_lambda/ccms_lambda.zip")

# #   vpc_config {
# #     subnet_ids         = # Replace with your private subnet(s)
# #     security_group_ids = # Replace with appropriate SG
# #   }

    # #layers are same as for cwa extract lambda
    # layers = [
    #   aws_lambda_layer_version.lambda_layer_oracle_python.arn,
    #   "arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPython:2"
    # ]
  # environment {
  #   variables = {
  #     PROCEDURE_SECRET_NAME = var.procedure_secret_name # new secret
  #     DB_SECRET_NAME       = var.db_secret_name # new db secret with User, Host, DSN
  #     LD_LIBRARY_PATH   = "/opt/instantclient_12_2_linux"
  #     ORACLE_HOME       = "/opt/instantclient_12_2_linux"
  #   }
  # }

#   timeout = 10
#   memory_size = 128
# }



