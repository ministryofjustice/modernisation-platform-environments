# resource "aws_lambda_function" "cwa_lambda" {
#   filename         = "cwa_lambda.zip"
#   function_name    = "cwa_lambda_function"
#   role             = aws_iam_role.cwa_lambda_role.arn
#   handler          = "index.test"
#   runtime          = "python3.11"
#   source_code_hash = filebase64sha256("lambda.zip")

# #   vpc_config {
# #     subnet_ids         = # Replace with your private subnet(s)
# #     security_group_ids = # Replace with appropriate SG
# #   }

#   timeout = 10
#   memory_size = 128
# }