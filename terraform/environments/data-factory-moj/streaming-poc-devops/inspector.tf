# ---------------------------------------------------------------------------------------------------------------------
# Inspector Findings Report - EventBridge Scheduler -> Lambda -> CreateFindingsReport -> S3
# ---------------------------------------------------------------------------------------------------------------------

# --- S3 bucket policy to allow Inspector to write reports ---

data "aws_iam_policy_document" "inspector_reports_bucket_policy" {
  for_each = toset(contains(local.deploy_to, local.environment) ? ["policy"] : [])
  statement {
    sid    = "AllowInspectorReports"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["inspector2.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.inspector_reports[0].arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "inspector_reports" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  bucket = aws_s3_bucket.inspector_reports[0].id
  policy = data.aws_iam_policy_document.inspector_reports_bucket_policy["policy"].json
}

# --- Lambda ---

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "lambda_inspector" {
  for_each = toset(contains(local.deploy_to, local.environment) ? ["lambda"] : [])
  statement {
    effect    = "Allow"
    actions   = ["inspector2:CreateFindingsReport"]
    resources = ["*"]
  }
  statement {
    effect  = "Allow"
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.name}-inspector-report:*"
    ]
  }
}

resource "aws_iam_role" "lambda_inspector" {
  count              = contains(local.deploy_to, local.environment) ? 1 : 0
  name               = "${local.name}-inspector-report"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.extended_tags
}

resource "aws_iam_role_policy" "lambda_inspector" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  name   = "${local.name}-inspector-report"
  role   = aws_iam_role.lambda_inspector[0].name
  policy = data.aws_iam_policy_document.lambda_inspector["lambda"].json
}

data "archive_file" "lambda_inspector" {
  type        = "zip"
  output_path = "${path.module}/inspector_report.zip"
  source {
    content  = <<-PYTHON
      import boto3, json, os

      def handler(event, context):
          client = boto3.client("inspector2")
          filters = json.loads(os.environ.get("INSPECTOR_FILTERS", "{}"))
          params = {
              "reportFormat": os.environ.get("REPORT_FORMAT", "JSON"),
              "s3Destination": {
                  "bucketName": os.environ["BUCKET_NAME"],
                  "kmsKeyArn":  os.environ["KMS_KEY_ARN"],
              },
          }
          if filters:
              params["filterCriteria"] = filters
          client.create_findings_report(**params)
    PYTHON
    filename = "inspector_report.py"
  }
}

resource "aws_cloudwatch_log_group" "lambda_inspector" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  name              = "/aws/lambda/${local.name}-inspector-report"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.inspector_s3[0].arn
  tags              = local.extended_tags
}

resource "aws_lambda_function" "inspector_report" {
  #checkov:skip=CKV_AWS_116:DLQ not required for scheduled reporting
  #checkov:skip=CKV_AWS_117:VPC not required - Lambda only calls AWS APIs via service endpoints
  #checkov:skip=CKV_AWS_272:code signing not required
  #checkov:skip=CKV_AWS_50:X-Ray tracing not required for scheduled reporting
  count                          = contains(local.deploy_to, local.environment) ? 1 : 0
  function_name                  = "${local.name}-inspector-report"
  role                           = aws_iam_role.lambda_inspector[0].arn
  filename                       = data.archive_file.lambda_inspector.output_path
  source_code_hash               = data.archive_file.lambda_inspector.output_base64sha256
  handler                        = "inspector_report.handler"
  runtime                        = "python3.13"
  kms_key_arn                    = aws_kms_key.inspector_s3[0].arn
  reserved_concurrent_executions = 1

  environment {
    variables = {
      BUCKET_NAME       = aws_s3_bucket.inspector_reports[0].bucket
      KMS_KEY_ARN       = aws_kms_key.inspector_s3[0].arn
      REPORT_FORMAT     = var.report_format
      INSPECTOR_FILTERS = length(var.inspector_filters) > 0 ? jsonencode(var.inspector_filters) : "{}"
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_inspector]
  tags       = local.extended_tags
}

# --- EventBridge Scheduler ---

data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "scheduler_lambda" {
  for_each = toset(contains(local.deploy_to, local.environment) ? ["scheduler"] : [])
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.inspector_report[0].arn]
  }
}

resource "aws_iam_role" "scheduler" {
  count              = contains(local.deploy_to, local.environment) ? 1 : 0
  name               = "${local.name}-inspector-scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume.json
  tags               = local.extended_tags
}

resource "aws_iam_role_policy" "scheduler_lambda" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  name   = "${local.name}-inspector-scheduler-lambda"
  role   = aws_iam_role.scheduler[0].name
  policy = data.aws_iam_policy_document.scheduler_lambda["scheduler"].json
}

resource "aws_scheduler_schedule" "inspector_report" {
  count       = contains(local.deploy_to, local.environment) ? 1 : 0
  name        = "${local.name}-inspector-report"
  description = "Trigger Inspector findings report generation"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = var.report_schedule
  kms_key_arn         = aws_kms_key.inspector_s3[0].arn

  target {
    arn      = aws_lambda_function.inspector_report[0].arn
    role_arn = aws_iam_role.scheduler[0].arn
  }
}
