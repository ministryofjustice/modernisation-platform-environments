#------------------------------------------------------------------------------
# S3 bucket for ap transfer logs
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "test_dump" {
  bucket_prefix = "test-dump-"

  tags = local.tags
}


resource "aws_s3_bucket_server_side_encryption_configuration" "test_dump" {
  bucket = aws_s3_bucket.test_dump.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "test_dump" {
  bucket                  = aws_s3_bucket.test_dump.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "test_dump" {
  bucket = aws_s3_bucket.test_dump.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "test_dump" {
  bucket = aws_s3_bucket.test_dump.id
  policy = data.aws_iam_policy_document.test_dump.json
}

data "aws_iam_policy_document" "test_dump" {
  statement {
    sid = "EnforceTLSv12orHigher"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.test_dump.arn,
      "${aws_s3_bucket.test_dump.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

resource "aws_s3_bucket_logging" "test_dump" {
  bucket = aws_s3_bucket.test_dump.id

  target_bucket = module.ap_transfer_log_bucket.bucket_id
  target_prefix = "log/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

#------------------------------------------------------------------------------
# S3 bucket for ap transfer logs
#------------------------------------------------------------------------------

module "ap_transfer_log_bucket" {
  source = "./modules/s3_log_bucket"

  source_bucket = aws_s3_bucket.test_dump
  account_id    = data.aws_caller_identity.current.account_id
  local_tags    = local.tags
}


#------------------------------------------------------------------------------
# S3 lambda function and IAM role definition
#------------------------------------------------------------------------------
data "archive_file" "ap_transfer_lambda" {
  type        = "zip"
  source_file = "ap_transfer_lambda.py"
  output_path = "ap_transfer_lambda.zip"
}


resource "aws_lambda_function" "ap_transfer_lambda" {
  filename      = "ap_transfer_lambda.zip"
  function_name = "ap-transfer-lambda"
  role          = aws_iam_role.ap_transfer_lambda.arn
  handler       = "ap_transfer_lambda.handler"
  runtime       = "python3.12"
  memory_size   = 4096
  timeout       = 900

  vpc_config {
    subnet_ids         = [aws_db_subnet_group.db.id]
    security_group_ids = [aws_security_group.db.id]
  }
  environment {
    variables = {
      DB_HOST     = aws_db_instance.database_2022.address
      # DB_NAME     = aws_db_instance.database_2022.name
      DB_USERNAME = aws_db_instance.database_2022.username
      DB_PASSWORD = aws_secretsmanager_secret_version.db_password.secret_string
    }
  }
}

data "aws_iam_policy_document" "lambda_vpc_doc" {
    statement {
      sid    = "VPC Config"
      effect = "Allow"
      actions = [
        "logs:CreateLogStream",
        # "ec2:CreateNetworkInterface",
        # "ec2:DescribeNetworkInterfaces",
        # "ec2:DescribeSubnets",
        # "ec2:DeleteNetworkInterface",
        # "ec2:AssignPrivateIpAddresses",
        # "ec2:UnassignPrivateIpAddresses"
      ]
      resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ap_transfer_lambda" {
    name = "ap_transfer_lambda"
    role = aws_iam_role.ap_transfer_lambda.id
    policy = data.aws_iam_policy_document.lambda_vpc_doc.json
}

resource "aws_iam_role" "ap_transfer_lambda" {
  name                = "ap-transfer-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.lambda_vpc_doc.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

resource "aws_lambda_permission" "ap_transfer_lambda" {
  statement_id  = "AllowPArquetToAP"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ap_transfer_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.test_dump.arn
}