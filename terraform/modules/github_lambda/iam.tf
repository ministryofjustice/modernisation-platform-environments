data "aws_iam_policy_document" "eventbridge_scheduler_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eventbridge_scheduler_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
    ]
    resources = [aws_lambda_function.github_workflow_trigger.arn]
  }
}

data "aws_iam_policy_document" "lambda_secrets_manager" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [aws_secretsmanager_secret.github_app.arn]
  }
}

resource "aws_iam_role" "eventbridge_scheduler" {
  name               = "${var.project_name}-eventbridge-scheduler"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_scheduler_assume_role.json
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project_name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "eventbridge_scheduler_lambda" {
  name   = "${var.project_name}-invoke-lambda"
  policy = data.aws_iam_policy_document.eventbridge_scheduler_lambda.json
  role   = aws_iam_role.eventbridge_scheduler.id
}

resource "aws_iam_role_policy" "lambda_secrets_manager" {
  name   = "${var.project_name}-secrets-manager"
  policy = data.aws_iam_policy_document.lambda_secrets_manager.json
  role   = aws_iam_role.lambda.id
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}
