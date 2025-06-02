resource "aws_cloudwatch_log_group" "ds" {
  name              = "/aws/directoryservice/${aws_directory_service_directory.ds_managed_ad.id}"
  retention_in_days = 365
  kms_key_id        = var.ds_managed_ad_secret_key
}

data "aws_iam_policy_document" "ad-log-policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    principals {
      identifiers = ["ds.amazonaws.com"]
      type        = "Service"
    }

    resources = ["${aws_cloudwatch_log_group.ds.arn}:*"]

    effect = "Allow"
  }
}

resource "aws_cloudwatch_log_resource_policy" "ad-log-policy" {
  policy_document = data.aws_iam_policy_document.ad-log-policy.json
  policy_name     = "${var.project_name}-ad-log-policy"
}


resource "aws_directory_service_log_subscription" "ad-log-policy" {
  directory_id   = aws_directory_service_directory.ds_managed_ad.id
  log_group_name = aws_cloudwatch_log_group.ds.name
}