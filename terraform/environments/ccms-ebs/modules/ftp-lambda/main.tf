
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
        Action : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::${var.ftp_bucket}",
          "arn:aws:s3:::${var.ftp_bucket}/*"
        ]
      },
      {
        Action : [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ],
        Effect   = "Allow",
        Resource = var.secret_arn
      }
    ]
  })
}




resource "aws_iam_role_policy_attachment" "ftp_lambda_policy_attach" {
  role       = aws_iam_role.ftp_lambda_role.name
  policy_arn = aws_iam_policy.ftp_policy.arn
}

### lambda layer for python dependencies
resource "aws_lambda_layer_version" "ftp_layer" {
  layer_name               = "ftpclientlayer"
  compatible_runtimes      = ["python3.13"]
  s3_bucket                = var.s3_bucket_ftp
  s3_key                   = var.s3_object_ftp_clientlibs
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
  memory_size   = var.lambda_memory # Sets memory defaults to 4gb
  layers        = [aws_lambda_layer_version.ftp_layer.arn]

  s3_bucket = var.s3_bucket_ftp
  s3_key    = var.s3_object_ftp_client

  ephemeral_storage {
    size = var.lambda_storage # Sets ephemeral storage defaults to 1GB (/tmp space)
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.ftp_sg.id]
  }

  environment {
    variables = {
      PORT                  = var.ftp_port
      PROTOCOL              = var.ftp_protocol
      FILETYPES             = var.ftp_file_types
      TRANSFERTYPE          = var.ftp_transfer_type
      LOCALPATH             = var.ftp_local_path
      REMOTEPATH            = var.ftp_remote_path
      REQUIRE_SSL           = var.ftp_require_ssl
      CA_CERT               = var.ftp_ca_cert
      CERT                  = var.ftp_cert
      KEY                   = var.ftp_key
      KEY_TYPE              = var.ftp_key_type
      S3BUCKET              = var.ftp_bucket
      FILEREMOVE            = var.ftp_file_remove
      SKIP_KEY_VERIFICATION = var.skip_key_verification
      SECRET_NAME           = var.secret_name
    }
  }
}
# ### cw rule for schedule
resource "aws_cloudwatch_event_rule" "ftp_schedule" {
  count               = contains(var.enabled_cron_in_environments, var.env) ? 1 : 0
  name                = "${var.lambda_name}-schedule"
  schedule_expression = var.env == "production" ? "cron(0 10 * * ? *)" : "cron(0 10 ? * MON-FRI *)"
}
### cw event lambda target
resource "aws_cloudwatch_event_target" "ftp_target" {
  count     = contains(var.enabled_cron_in_environments, var.env) ? 1 : 0
  rule      = aws_cloudwatch_event_rule.ftp_schedule[count.index].name
  target_id = "ftp-lambda"
  arn       = aws_lambda_function.ftp_lambda.arn
}

### allow cw to event in lambda
resource "aws_lambda_permission" "ftp_permission" {
  count         = contains(var.enabled_cron_in_environments, var.env) ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ftp_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ftp_schedule[count.index].arn
}