data "aws_iam_policy_document" "managed_apache_flink" {
  statement {
    sid     = "AllowS3SourceCode"
    effect  = "Allow"
    actions = ["s3:*"] #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = [
      data.aws_s3_bucket.source_bucket.arn,
      "${data.aws_s3_bucket.source_bucket.arn}/*",
    ]
  }

  dynamic "statement" {
    for_each = length(var.additional_s3_bucket_arn_list) > 0 ? [1] : []

    content {
      sid       = "AllowAdditionalS3"
      effect    = "Allow"
      actions   = ["s3:*"] #tfsec:ignore:aws-iam-no-policy-wildcards
      resources = var.additional_s3_bucket_arn_list
    }
  }

  dynamic "statement" {
    for_each = var.config_property_group.additional_iam_statements

    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

data "aws_iam_policy_document" "managed_apache_flink_application_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["kinesisanalytics.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "managed_apache_flink_application" {
  name   = "${lower(var.config_property_group.app_name)}-flink-iam-policy"
  policy = data.aws_iam_policy_document.managed_apache_flink.json
  tags   = var.tags
}

resource "aws_iam_role" "managed_apache_flink_application" {
  name               = "${lower(var.config_property_group.app_name)}-flink-iam-role"
  assume_role_policy = data.aws_iam_policy_document.managed_apache_flink_application_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "managed_apache_flink_application" {
  role       = aws_iam_role.managed_apache_flink_application.name
  policy_arn = aws_iam_policy.managed_apache_flink_application.arn
}

resource "aws_iam_role_policy_attachment" "managed_apache_flink_application_amazonvpcfullaccess" {
  role       = aws_iam_role.managed_apache_flink_application.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "managed_apache_flink_application_cloudwatchfullaccess" {
  role       = aws_iam_role.managed_apache_flink_application.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}
