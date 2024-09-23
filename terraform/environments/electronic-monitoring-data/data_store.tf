

resource "aws_s3_bucket_notification" "data_store" {
  bucket = module.s3-data-bucket.bucket.id

  # Only for copy events as those are events triggered by data being copied
  # from landing bucket.
  lambda_function {
    lambda_function_arn = aws_lambda_function.calculate_checksum_lambda.arn
    events = [
      "s3:ObjectCreated:*"
    ]
  }

  # Only for copy events as those are events triggered by data being copied
  #  from landing bucket.
  lambda_function {
    lambda_function_arn = aws_lambda_function.summarise_zip_lambda.arn
    events              = [
      "s3:ObjectCreated:*"
    ]
  }

  depends_on = [
    aws_lambda_permission.s3_allow_calculate_checksum_lambda,
    aws_lambda_permission.s3_allow_summarise_zip_lambda,
  ]
}

#------------------------------------------------------------------------------
# S3 lambda function to calculate data store file checksums
#------------------------------------------------------------------------------

variable "checksum_algorithm" {
  type        = string
  description = "Select Checksum Algorithm. Default and recommended choice is SHA256, however CRC32, CRC32C, SHA1 are also available."
  default     = "SHA256"
}

data "archive_file" "calculate_checksum_lambda" {
  type        = "zip"
  source_file = "lambdas/calculate_checksum_lambda.py"
  output_path = "lambdas/calculate_checksum_lambda.zip"
}

resource "aws_lambda_function" "calculate_checksum_lambda" {
  filename      = "lambdas/calculate_checksum_lambda.zip"
  function_name = "calculate-checksum-lambda"
  role          = aws_iam_role.calculate_checksum_lambda.arn
  handler       = "calculate_checksum_lambda.handler"
  runtime       = "python3.12"
  memory_size   = 4096
  timeout       = 900

  environment {
    variables = {
      Checksum = var.checksum_algorithm
    }
  }

  tags = local.tags
}

resource "aws_iam_role" "calculate_checksum_lambda" {
  name                = "calculate-checksum-lambda-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

data "aws_iam_policy_document" "calculate_checksum_lambda" {
  statement {
    sid    = "S3Permissions"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:GetObjectAttributes",
      "s3:GetObjectVersionAttributes",
      "s3:ListBucket"
    ]
    resources = ["${module.s3-data-bucket.bucket.arn}/*"]
  }
}

resource "aws_iam_role_policy" "calculate_checksum_lambda" {
  name   = "calculate_checksum-lambda-iam-policy"
  role   = aws_iam_role.calculate_checksum_lambda.id
  policy = data.aws_iam_policy_document.calculate_checksum_lambda.json
}

resource "aws_lambda_permission" "s3_allow_calculate_checksum_lambda" {
  statement_id  = "AllowCalculateChecksumExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calculate_checksum_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3-data-bucket.bucket.arn
}

#------------------------------------------------------------------------------
# S3 lambda function to perform zip file summary
#------------------------------------------------------------------------------

data "archive_file" "summarise_zip_lambda" {
  type        = "zip"
  source_file = "lambdas/summarise_zip_lambda.py"
  output_path = "lambdas/summarise_zip_lambda.zip"
}

resource "aws_lambda_function" "summarise_zip_lambda" {
  filename         = "lambdas/summarise_zip_lambda.zip"
  function_name    = "summarise-zip-lambda"
  role             = aws_iam_role.summarise_zip_lambda.arn
  handler          = "summarise_zip_lambda.handler"
  runtime          = "python3.12"
  timeout          = 900
  memory_size      = 1024
  layers           = ["arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPythonV2:67"]
  source_code_hash = data.archive_file.summarise_zip_lambda.output_base64sha256
  tags             = local.tags
}

resource "aws_iam_role" "summarise_zip_lambda" {
  name                = "summarise-zip-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

data "aws_iam_policy_document" "summarise_zip_lambda" {
  statement {
    sid    = "S3Permissions"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = ["${module.s3-data-bucket.bucket.arn}/*"]
  }
}

resource "aws_iam_role_policy" "summarise_zip_lambda" {
  name   = "summarise-zip-iam-policy"
  role   = aws_iam_role.summarise_zip_lambda.id
  policy = data.aws_iam_policy_document.summarise_zip_lambda.json
}

resource "aws_lambda_permission" "s3_allow_summarise_zip_lambda" {
  statement_id  = "AllowSummariseZipExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.summarise_zip_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3-data-bucket.bucket.arn
}
