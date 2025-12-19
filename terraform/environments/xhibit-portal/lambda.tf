data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "snapshot_lambda" {

  name = "snapshot_lambda"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy" "snapshot_lambda_inline" {
  # checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"
  # checkov:skip=CKV_AWS_290: "Ensure IAM policies does not allow write access without constraints"
  name = "snapshot_lambda_policy"
  role = aws_iam_role.snapshot_lambda.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeImageAttribute",
          "ec2:RegisterImage",
          "ec2:DescribeImages",
          "ec2:DescribeSnapshotAttribute",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:CreateImage",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

#Create ZIP archive and lambda
data "archive_file" "lambda_zip" {
  type             = "zip"
  source_file      = "lambda/root_snapshot_to_ami.py"
  output_file_mode = "0666"
  output_path      = "lambda/lambda_function.zip"
}

resource "aws_lambda_function" "root_snapshot_to_ami" {
  # checkov:skip=CKV_AWS_117: "Ensure that AWS Lambda function is configured inside a VPC"
  # checkov:skip=CKV_AWS_116: "DLQ not required"
  # checkov:skip=CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing"
  filename                       = "lambda/lambda_function.zip"
  function_name                  = "root_snapshot_to_ami"
  role                           = aws_iam_role.snapshot_lambda.arn
  handler                        = "root_snapshot_to_ami.lambda_handler"
  source_code_hash               = data.archive_file.lambda_zip.output_base64sha256
  runtime                        = "python3.12"
  memory_size                    = "512"
  timeout                        = "120"
  reserved_concurrent_executions = 1

  tracing_config {
    mode = "Active"
  }

  tags = merge(
    local.tags,
    {
      Name = "root_snapshot_to_ami-${local.application_name}"
    }
  )
}

resource "aws_cloudwatch_event_rule" "every_day_0130" {
  name                = "run-daily-0130"
  description         = "Runs daily at 1:30am"
  schedule_expression = "cron(30 1 * * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_every_day" {
  rule      = aws_cloudwatch_event_rule.every_day_0130.name
  target_id = "root_snapshot_to_ami"
  arn       = aws_lambda_function.root_snapshot_to_ami.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.root_snapshot_to_ami.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_day_0130.arn
}


# Delete AMI Lambda
data "aws_iam_policy_document" "lambda_delete_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "delete_snapshot_lambda" {

  name = "delete_snapshot_lambda"

  assume_role_policy = data.aws_iam_policy_document.lambda_delete_assume_role_policy.json
}

resource "aws_iam_role_policy" "delete_snapshot_lambda_inline" {
  # checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"
  # checkov:skip=CKV_AWS_290: "Ensure IAM policies does not allow write access without constraints"
  name = "delete_snapshot_lambda_policy"
  role = aws_iam_role.delete_snapshot_lambda.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeImageAttribute",
          "ec2:DeregisterImage",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshotAttribute",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DeleteSnapshot",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

#Create ZIP archive and lambda
data "archive_file" "delete_lambda_zip" {
  type             = "zip"
  source_file      = "lambda/delete_old_ami.py"
  output_file_mode = "0666"
  output_path      = "lambda/delete_old_ami.zip"
}

# tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "delete_old_ami" {
  # checkov:skip=CKV_AWS_50: "X-ray tracing is not required"
  # checkov:skip=CKV_AWS_117: "Lambda is not environment specific"
  # checkov:skip=CKV_AWS_116: "DLQ not required"
  # checkov:skip=CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing"
  # checkov:skip=CKV_AWS_363: "Ensure Lambda Runtime is not deprecated"
  # checkov:skip=CKV_AWS_173: "Check encryption settings for Lambda environmental variable"
  filename         = "lambda/delete_old_ami.zip"
  function_name    = "delete_old_ami"
  role             = aws_iam_role.delete_snapshot_lambda.arn
  handler          = "delete_old_ami.lambda_handler"
  source_code_hash = data.archive_file.delete_lambda_zip.output_base64sha256
  runtime          = "python3.12"

  environment {
    variables = {
      DRY_RUN = "false" # Pass dry_run as an environment variable
    }
  }

  # "large" amount of memory because of the amount of snapshots
  memory_size                    = "1280"
  timeout                        = "240"
  reserved_concurrent_executions = 1
}

resource "aws_cloudwatch_event_rule" "every_day_0230" {
  name                = "run-daily-0230"
  description         = "Runs daily at 2:30am"
  schedule_expression = "cron(30 2 * * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_every_day_0230" {
  rule      = aws_cloudwatch_event_rule.every_day_0230.name
  target_id = "delete_old_ami"
  arn       = aws_lambda_function.delete_old_ami.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_delete_ami_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_old_ami.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_day_0230.arn
}
