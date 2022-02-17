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

  inline_policy {
    name = "snapshot_lambda_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ec2:DescribeImageAttribute",
            "ec2:DescribeImages",
            "ec2:DescribeSnapshotAttribute",
            "ec2:DescribeSnapshots",
            "ec2:DescribeVolumeAttribute",
            "ec2:DescribeVolume",
            "ec2:DescribeTags",
            "ec2:CreateTags",
            "ec2:DeleteTags",
            "ec2:CreateImage",
            "ec2:CreateVolume",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

#Create ZIP archive and lambda
data "archive_file" "lambda_zip" {

  type        = "zip"
  source_file = "lambda/index.py"
  output_path = "lambda/lambda_function.zip"
}

# tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "root_snapshot_to_ami" {
  # checkov:skip=CKV_AWS_50: "X-ray tracing is not required"
  # checkov:skip=CKV_AWS_117: "Lambda is not environment specific"
  # checkov:skip=CKV_AWS_116: "DLQ not required"
  filename                       = "lambda/lambda_function.zip"
  function_name                  = "root_snapshot_to_ami"
  role                           = aws_iam_role.snapshot_lambda.arn
  handler                        = "index.lambda_handler"
  source_code_hash               = data.archive_file.lambda_zip.output_path
  runtime                        = "python3.8"
  reserved_concurrent_executions = 1
}

resource "aws_cloudwatch_event_rule" "every_day" {
  name                = "run-daily"
  description         = "Runs daily at 8pm"
  schedule_expression = "cron(0 20 * * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_every_day" {
  rule      = aws_cloudwatch_event_rule.every_day.name
  target_id = "root_snapshot_to_ami"
  arn       = aws_lambda_function.root_snapshot_to_ami.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.root_snapshot_to_ami.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_day.arn
}
