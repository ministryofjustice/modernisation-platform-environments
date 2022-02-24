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
  count = "${local.is-production ? 1 : 0}"

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
            "logs:PutLogEvents"
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
  count = "${local.is-production ? 1 : 0}"
  # checkov:skip=CKV_AWS_50: "X-ray tracing is not required"
  # checkov:skip=CKV_AWS_117: "Lambda is not environment specific"
  # checkov:skip=CKV_AWS_116: "DLQ not required"
  filename                       = "lambda/lambda_function.zip"
  function_name                  = "root_snapshot_to_ami"
  role                           = aws_iam_role.snapshot_lambda[count.index].arn
  handler                        = "index.lambda_handler"
  source_code_hash               = data.archive_file.lambda_zip.output_path
  runtime                        = "python3.8"
  reserved_concurrent_executions = 1
  timeout                        = "120"
}

resource "aws_cloudwatch_event_rule" "every_day" {
  count = "${local.is-production ? 1 : 0}"
  name                = "run-daily"
  description         = "Runs daily at 1:30am"
  schedule_expression = "cron(30 1 * * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_every_day" {
  count = "${local.is-production ? 1 : 0}"
  rule      = aws_cloudwatch_event_rule.every_day[count.index].name
  target_id = "root_snapshot_to_ami"
  arn       = aws_lambda_function.root_snapshot_to_ami[count.index].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  count = "${local.is-production ? 1 : 0}"
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.root_snapshot_to_ami[count.index].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_day[count.index].arn
}
