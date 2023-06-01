##################################################
# Airflow
##################################################

# Based on https://docs.aws.amazon.com/mwaa/latest/userguide/mwaa-create-role.html#mwaa-create-role-json but without CMK permissions
# TODO: Update placeholders
data "aws_iam_policy_document" "airflow_execution_policy" {
  statement {
    sid       = "AllowAirflowPublishMetrics"
    effect    = "Allow"
    actions   = ["airflow:PublishMetrics"]
    resources = ["arn:aws:airflow:{your-region}:{your-account-id}:environment/{your-environment-name}"]
  }
  statement {
    sid       = "DenyS3ListAllMyBuckets"
    effect    = "Deny"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }
  statement {
    sid    = "AllowS3GetListBucketObjects"
    effect = "Allow"
    actions = [
      "s3:GetBucket*",
      "s3:GetObject*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::{your-bucket-name}",
      "arn:aws:s3:::{your-bucket-name}/*"
    ]
  }
  statement {
    sid    = "AllowCloudWatchLogsCreatePutGet"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:GetLogRecord",
      "logs:GetLogGroupFields",
      "logs:GetQueryResults"
    ]
    resources = ["arn:aws:logs:{your-region}:{your-account-id}:log-group:airflow-{your-environment-name}-*"]
  }
  statement {
    sid       = "AllowCloudWatchLogGroupsDescribe"
    effect    = "Allow"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }
  statement {
    sid       = "AllowS3GetAccountPublicAccessBlock"
    effect    = "Allow"
    actions   = ["s3:GetAccountPublicAccessBlock"]
    resources = ["*"]
  }
  statement {
    sid       = "AllowCloudWatchPutMetricData"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
  statement {
    sid    = "AllowSQSChangeDeleteGetReceiveSend"
    effect = "Allow"
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage"
    ]
    resources = ["arn:aws:sqs:{your-region}:*:airflow-celery-*"]
  }
}

module "airflow_execution_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.20.0"

  name   = "data-platform-airflow-execution-policy"
  policy = data.aws_iam_policy_document.airflow_execution_policy.json
}
