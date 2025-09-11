resource "aws_iam_role" "lambda_role" {
  name               = "${var.env_name}-slack-alerts-role"
  description        = "Role enabling Lambda to access Slack for sending alerts"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.json
  tags               = merge(var.tags, { Name = "${var.env_name}-slack-alerts-role" })
}

data "aws_iam_policy_document" "assume_role_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_policy_document" {
  #checkov:skip=CKV_AWS_356 "ignore"
  #checkov:skip=CKV_AWS_111 "ignore"
  statement {
    sid       = "Logging"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }
  statement {
    sid       = "Parameters"
    effect    = "Allow"
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/deliusawsalerts/slack-token"]
    actions   = ["ssm:GetParameter"]
  }
  statement {
    sid       = "ParameterDecryption"
    effect    = "Allow"
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alias/aws/ssm"]
    actions   = ["kms:Decrypt"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "${var.env_name}-slack-alert-role-policy"
  policy = data.aws_iam_policy_document.lambda_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}