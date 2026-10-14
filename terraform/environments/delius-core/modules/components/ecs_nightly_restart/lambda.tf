locals {
  lambda_name         = "${var.service_name}-nightly-restart"
  schedule_expression = "cron(15 02 * * ? *)" # 02:15 every day
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_exec_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ecs:UpdateService"]
    resources = [var.service_arn]
  }
}

resource "aws_cloudwatch_event_rule" "rule" {
  name                = "${local.lambda_name}-rule"
  schedule_expression = local.schedule_expression
}

resource "aws_cloudwatch_event_target" "target" {
  rule = aws_cloudwatch_event_rule.rule.name
  arn  = aws_lambda_function.nightly_restart_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  function_name = aws_lambda_function.nightly_restart_lambda.function_name
  source_arn    = aws_cloudwatch_event_rule.rule.arn
}

resource "aws_iam_role" "lambda_role" {
  name               = "${local.lambda_name}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  description        = "Lambda execution role for the ${local.lambda_name} function"
}

resource "aws_iam_role_policy" "lambda_role_policy" {
  name   = "${local.lambda_name}-exec-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_exec_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "nightly_restart_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/files/nightly-restart-lambda.zip"
  source {
    content  = file("${path.module}/lambda/nightly-restart-lambda.py")
    filename = "lambda.py"
  }
}

resource "aws_lambda_function" "nightly_restart_lambda" {
  #checkov:skip=CKV_AWS_117: "VPC not required - Lambda only calls AWS APIs via service endpoints"
  #checkov:skip=CKV_AWS_173: "Env Vars are not sensitive"
  #checkov:skip=CKV_AWS_272: "Doesn't require code signing"
  #checkov:skip=CKV_AWS_116: "DLQ not required"
  #checkov:skip=CKV_AWS_50: "X-Ray tracing not required"

  function_name    = local.lambda_name
  description      = "Lambda function to restart the ${var.service_name} ECS service nightly"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.14"
  handler          = "lambda.handler"
  filename         = data.archive_file.nightly_restart_lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.nightly_restart_lambda_zip.output_path)
  tags             = { Name = local.lambda_name }
  environment {
    variables = {
      CLUSTER       = var.cluster_name
      SERVICE       = var.service_name
      DESIRED_COUNT = var.task_count
    }
  }
}