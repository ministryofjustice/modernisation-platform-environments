data "aws_iam_policy_document" "api_gateway_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

data "aws_iam_policy_document" "api_gateway_put_events" {
  statement {
    actions   = ["events:PutEvents"]
    resources = [module.eventbridge_bus.eventbridge_bus_arn]
  }
}

resource "aws_iam_role" "api_gateway_put_events" {
  name               = "${local.resource_name_prefix}-put-events"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy" "api_gateway_put_events" {
  name   = "put-events"
  role   = aws_iam_role.api_gateway_put_events.id
  policy = data.aws_iam_policy_document.api_gateway_put_events.json
}
