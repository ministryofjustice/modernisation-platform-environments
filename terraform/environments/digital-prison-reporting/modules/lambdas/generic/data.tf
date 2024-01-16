data "archive_file" "lambda" {
  type        = "Image"
  source_file = "lambda.js"
  output_path = "lambda_function_payload.zip"
}