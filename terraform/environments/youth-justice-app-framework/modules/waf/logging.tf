resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "/aws/waf/${var.waf_name}-logs"
  retention_in_days = 30
  tags              = local.tags
}


data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "${var.waf_name}-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

data "aws_iam_policy_document" "firehose_policy" {
  statement {
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["${aws_cloudwatch_log_group.waf_logs.arn}:*"]
  }
}

resource "aws_iam_role_policy" "firehose_policy" {
  role   = aws_iam_role.firehose_role.id
  policy = data.aws_iam_policy_document.firehose_policy.json
}


resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  name        = "${var.waf_name}-waf-logs"
  destination = "cloudwatch_logs"

  cloudwatch_logs_configuration {
    log_group_name  = aws_cloudwatch_log_group.waf_logs.name
    log_stream_name = "waf-logs-stream"
  }

  role_arn = aws_iam_role.firehose_role.arn
}

resource "aws_wafv2_web_acl_logging_configuration" "regional" {
  count = var.scope != "CLOUDFRONT" ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.waf[0].arn
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_logs.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "cloudfront" {
  count    = var.scope == "CLOUDFRONT" ? 1 : 0
  provider = aws.us-east-1

  resource_arn            = aws_wafv2_web_acl.cf[0].arn
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_logs.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}