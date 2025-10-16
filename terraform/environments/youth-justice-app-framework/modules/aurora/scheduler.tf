# Lambda function to stop and start Aurora Cluster based on EC2 Instance tags

resource "aws_iam_role" "scheduler_aurora_lambda_role" {
  count              = var.create_sheduler ? 1 : 0
  name               = "scheduler_aurora_lambda_role"
  description        = "Used to Stop and Start an Aurora cluster"
  path               = "/"
  tags               = local.all_tags
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "scheduler_aurora_lambda_policy" {
  count       = var.create_sheduler ? 1 : 0
  name        = "scheduler_aurora_lambda_policy"
  description = "Policies required to Stop and Start an Aurora cluster"
  tags        = local.all_tags
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "rds:DescribeDBClusterParameters",
                "rds:DescribeDBEngineVersions",
                "rds:DescribeGlobalClusters",
                "rds:DescribePendingMaintenanceActions",
                "rds:DescribeDBLogFiles",
                "rds:StopDBInstance",
                "rds:StartDBInstance",
                "rds:DescribeReservedDBInstancesOfferings",
                "rds:DescribeReservedDBInstances",
                "rds:ListTagsForResource",
                "rds:DescribeValidDBInstanceModifications",
                "rds:DescribeDBInstances",
                "rds:DescribeSourceRegions",
                "rds:DescribeDBClusterEndpoints",
                "rds:DescribeDBClusters",
                "rds:DescribeDBClusterParameterGroups",
                "rds:DescribeOptionGroups"
              ],
           "Resource": [
              "arn:aws:rds:eu-west-2:${var.aws_account_id}:db:*"
             ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "rds:StartDBCluster",
                "rds:StopDBCluster"
              ],
            "Resource": [
              "${module.aurora.cluster_arn}"
             ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
   	            "logs:PutLogEvents"
              ],
           "Resource": [
                  "arn:aws:logs:*:*:*"
             ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "scheduler_aurora_lambda_policy" {
  count      = var.create_sheduler ? 1 : 0
  role       = aws_iam_role.scheduler_aurora_lambda_role[0].name
  policy_arn = aws_iam_policy.scheduler_aurora_lambda_policy[0].arn
}

data "archive_file" "python_lambda_start_aurora_cluster" {
  count       = var.create_sheduler ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/code/scheduler-start-aurora-cluster.py"
  output_path = "${path.module}/zip/scheduler-start-aurora-cluster.zip"
}


resource "aws_lambda_function" "start_aurora_lambda_function" {
  #checkov:skip=CKV_AWS_50: "X-ray tracing is not required"
  #checkov:skip=CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing"#checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  #checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  #checkov:skip=CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit"
  #checkov:skip=CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)"
  #checkov:skip=CKV_AWS_363: "fix before deprecation date"
  count            = var.create_sheduler ? 1 : 0
  function_name    = "start-aurora-cluster"
  description      = "Used for starting Aurora cluster"
  filename         = "${path.module}/zip/scheduler-start-aurora-cluster.zip"
  source_code_hash = data.archive_file.python_lambda_start_aurora_cluster[0].output_base64sha256
  role             = aws_iam_role.scheduler_aurora_lambda_role[0].arn
  runtime          = "python3.9"
  handler          = "scheduler-start-aurora-cluster.lambda_handler"
  timeout          = 5
  kms_key_arn      = var.kms_key_arn
  environment { // Key value pair used as tags in RDS
    variables = {
      KEY    = "schedule",
      REGION = "eu-west-2",
      VALUE  = "lambda"
    }
  }
  tags = local.all_tags
}

resource "aws_cloudwatch_event_rule" "start-aurora-cluster" {
  count               = var.create_sheduler ? 1 : 0
  name                = "start-aurora-cluster"
  description         = "Start Aurora Cluster"
  schedule_expression = var.start_aurora_cluster_schedule
  tags                = local.all_tags
}

resource "aws_cloudwatch_event_target" "start-lambda-function-target" {
  count     = var.create_sheduler ? 1 : 0
  target_id = "start-aurora-cluster"
  rule      = aws_cloudwatch_event_rule.start-aurora-cluster[0].name
  arn       = aws_lambda_function.start_aurora_lambda_function[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge_invoke_aurora_start" {
  count         = var.create_sheduler ? 1 : 0
  statement_id  = "AllowExecutionFromStartAuroraCluster"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_aurora_lambda_function[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start-aurora-cluster[0].arn
}

data "archive_file" "python_lambda_stop_aurora_cluster" {
  count       = var.create_sheduler ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/code/scheduler-stop-aurora-cluster.py"
  output_path = "${path.module}/zip/scheduler-stop-aurora-cluster.zip"
}


resource "aws_lambda_function" "stop_aurora_lambda_function" {
  #checkov:skip=CKV_AWS_50: "X-ray tracing is not required"
  #checkov:skip=CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing"#checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  #checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  #checkov:skip=CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit"
  #checkov:skip=CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)"
  #checkov:skip=CKV_AWS_363: "fix at before deprecation date"
  count            = var.create_sheduler ? 1 : 0
  function_name    = "stop-aurora-cluster"
  description      = "Used for stopping Aurora cluster"
  filename         = "${path.module}/zip/scheduler-stop-aurora-cluster.zip"
  source_code_hash = data.archive_file.python_lambda_stop_aurora_cluster[0].output_base64sha256
  role             = aws_iam_role.scheduler_aurora_lambda_role[0].arn
  runtime          = "python3.9"
  handler          = "scheduler-stop-aurora-cluster.lambda_handler"
  timeout          = 5
  kms_key_arn      = var.kms_key_arn
  environment { // Key value pair used as tags in RDS
    variables = {
      KEY    = "schedule",
      REGION = "eu-west-2",
      VALUE  = "lambda"
    }
  }
  tags = local.all_tags
}

resource "aws_cloudwatch_event_rule" "stop-aurora-cluster" {
  count               = var.create_sheduler ? 1 : 0
  name                = "stop-aurora-cluster"
  description         = "Stop Aurora Cluster"
  schedule_expression = var.stop_aurora_cluster_schedule
  tags                = local.all_tags
}

resource "aws_cloudwatch_event_target" "stop-lambda-function-target" {
  count     = var.create_sheduler ? 1 : 0
  target_id = "aurora-cluster"
  rule      = aws_cloudwatch_event_rule.stop-aurora-cluster[0].name
  arn       = aws_lambda_function.stop_aurora_lambda_function[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge_invoke_aurora_stop" {
  count         = var.create_sheduler ? 1 : 0
  statement_id  = "AllowExecutionFromStopAuroraCluster"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_aurora_lambda_function[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop-aurora-cluster[0].arn
}

resource "aws_cloudwatch_log_group" "function_log_group_start" {
  count             = var.create_sheduler ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.start_aurora_lambda_function[0].function_name}"
  retention_in_days = 365
  kms_key_id        = var.kms_key_arn
  lifecycle {
    prevent_destroy = false
  }
  tags = local.all_tags
}

resource "aws_cloudwatch_log_group" "function_log_group_stop" {
  count             = var.create_sheduler ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.stop_aurora_lambda_function[0].function_name}"
  retention_in_days = 365
  kms_key_id        = var.kms_key_arn
  lifecycle {
    prevent_destroy = false
  }
  tags = local.all_tags
}
