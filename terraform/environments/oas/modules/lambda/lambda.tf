# module "lambda_function" {
#   source = "terraform-aws-modules/lambda/aws"

#   function_name = "SecretsRotation"
#   description   = "Secrets Manager password rotation for RDS"
#   handler       = "index.lambda_handler"
#   runtime       = "python3.8"

#   source_path = "../src/lambda-function1"

#   tags = {
#     Name = "SecretsRotation"
#   }
# }