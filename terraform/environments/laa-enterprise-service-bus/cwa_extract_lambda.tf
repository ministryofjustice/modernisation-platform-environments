#####################################
### Package the Lambda function code
#####################################

data "archive_file" "cwa_extract" {
  type        = "zip"
  source_file = "lambda/filename.py"
  output_path = "lambda/filename.zip"
}


######################################
### Lambda SG
######################################

resource "aws_security_group" "cwa_extract" {
  name        = "${local.application_name_short}-${local.environment}-cwa-extract-lambda-security-group"
  description = "CWA Extract Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    description = "outbound access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa-extract-lambda-security-group" }
  )
}

######################################
### Lambda Resources
######################################

resource "aws_lambda_function" "cwa_extract" {

  description      = "Connect to CWA DB, extracts data into JSON files, uploads them to S3 and creates SNS message and SQS entries with S3 references"
  function_name    = "cwa_extract_function"
  role             = aws_iam_role.cwa_lambda_role.arn
  handler          = "index.test"
  filename         = data.archive_file.cwa_extract.output_path
  source_code_hash = data.archive_file.cwa_extract.output_base64sha256
  timeout          = 10
  memory_size      = 128

  runtime          = "python3.11"

  vpc_config {
    security_group_ids = [aws_security_group.cwa_extract.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }

  # environment {
  #   variables = {
  #     S3_BUCKET_NAME = aws_s3_bucket.data.bucket
  #     SNS_TOPIC_ARN  = aws_sns_topic.cwa_extract.arn
  #     SQS_QUEUE_URL  = aws_sqs_queue.cwa_extract.url
  #   }
  # }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa-extract" }
  )
}