
locals {
  lambda_src_dir = "${path.module}/lambda/ftp-client"
  lambda_zip     = "${path.module}/lambda/ftp-client/ftp-client.zip"
  layer_src_dir = "${path.module}/lambda/lambda-layer"
}

## sg for ftp
resource "aws_security_group" "ftp_sg" {
  name        = "${var.lambda_name}-sg"
  description = "Allow outbound connection"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## lambda role for ftp
resource "aws_iam_role" "ftp_lambda_role" {
  name = "${var.lambda_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.ftp_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "ftp_policy" {
  name = "${var.lambda_name}-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = ["s3:*"],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::${var.ftp_bucket}",
          "arn:aws:s3:::${var.ftp_bucket}/*"
        ]
      },
      {
        Action: [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
        ],
        Effect = "Allow",
        Resource = var.secret_arn
      }
    ]
  })
}




resource "aws_iam_role_policy_attachment" "ftp_lambda_policy_attach" {
  role       = aws_iam_role.ftp_lambda_role.name
  policy_arn = aws_iam_policy.ftp_policy.arn
}

# Create ZIP archive of lambda_code/
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = local.lambda_src_dir
  output_path = local.lambda_zip
}


# Create ZIP archive of lambda layer/
data "archive_file" "lambda_layer" {
  type        = "zip"
  source_dir  = local.layer_src_dir   # folder containing 'python/' directory
  output_path = "${local.layer_src_dir}/lambda-layer.zip"
}


### lambda layer for python dependencies
resource "aws_lambda_layer_version" "ftp_layer" {
  layer_name               = "ftpclientlibs"
  compatible_runtimes      = ["python3.13"]
  # s3_bucket                = var.s3_bucket_ftp
  # s3_key                   = var.s3_object_ftp_clientlibs
  filename    = data.archive_file.lambda_layer.output_path
  source_code_hash = data.archive_file.lambda_layer.output_base64sha256
  compatible_architectures = ["x86_64"]
  description              = "Lambda Layer for ccms ebs ftp lambda contains pycurl and other dependencies"
}
#### lambda function for ftp inbound
resource "aws_lambda_function" "ftp_lambda" {
  function_name = var.lambda_name
  role          = aws_iam_role.ftp_lambda_role.arn
  handler       = "ftp-client.lambda_handler"
  runtime       = "python3.13"
  timeout       = 900
  memory_size   = 256
  # s3_bucket = var.s3_bucket_ftp
  # s3_key    = var.s3_object_ftp_client
  layers    = [aws_lambda_layer_version.ftp_layer.arn]
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.ftp_sg.id]
  }

  environment {
    variables = {
      PORT         = var.ftp_port
      PROTOCOL     = var.ftp_protocol
      FILETYPES    = var.ftp_file_types
      TRANSFERTYPE = var.ftp_transfer_type
      LOCALPATH    = var.ftp_local_path
      REMOTEPATH   = var.ftp_remote_path
      REQUIRE_SSL  = var.ftp_require_ssl
      CA_CERT      = var.ftp_ca_cert
      CERT         = var.ftp_cert
      KEY          = var.ftp_key
      KEY_TYPE     = var.ftp_key_type
      S3BUCKET     = var.ftp_bucket
      FILEREMOVE   = var.ftp_file_remove
      SKIP_KEY_VERIFICATION= var.skip_key_verification
      SECRET_NAME = var.secret_name
    }
  }
}
### cw rule for schedule
resource "aws_cloudwatch_event_rule" "ftp_schedule" {
  name                = "${var.lambda_name}-schedule"
  schedule_expression = var.ftp_cron
}
### cw event lambda target
resource "aws_cloudwatch_event_target" "ftp_target" {
  rule      = aws_cloudwatch_event_rule.ftp_schedule.name
  target_id = "ftp-lambda"
  arn       = aws_lambda_function.ftp_lambda.arn
}

### attaching lambda iam role to inbound bucket
resource "aws_lambda_permission" "ftp_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ftp_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ftp_schedule.arn
}