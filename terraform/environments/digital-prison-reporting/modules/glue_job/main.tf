locals {
  default_arguments = {
    "--job-language"                     = var.job_language
    "--job-bookmark-option"              = var.bookmark_options[var.bookmark]
    "--TempDir"                          = var.temp_dir
    "--checkpoint.location"              = var.checkpoint_dir
    "--spark-event-logs-path"            = var.spark_event_logs
    "--continuous-log-logGroup"          = try(aws_cloudwatch_log_group.job[0].name, "null")
    "--enable-continuous-cloudwatch-log" = "false"
    "--enable-glue-datacatalog"          = "true"
    "--enable-job-insights"              = "true"
    "--continuous-log-logStreamPrefix"   = var.continuous_log_stream_prefix
    "--enable-continuous-log-filter"     = var.enable_continuous_log_filter
    "--enable-spark-ui"                  = var.enable_spark_ui
  }

  tags = merge(
    var.tags,
    {
      Dept = "Digital-Prison-Reporting"
    }
  )
}

resource "aws_glue_job" "glue_job" {
  count = var.create_job ? 1 : 0

  name        = var.name
  role_arn    = var.create_role ? join("", aws_iam_role.glue-service-role.*.arn) : var.role_arn
  connections = var.connections
  # max_capacity         = var.dpu
  description            = var.description
  glue_version           = var.glue_version
  max_retries            = var.max_retries
  security_configuration = var.create_security_configuration ? join("", aws_glue_security_configuration.sec_cfg.*.id) : var.security_configuration
  worker_type            = var.worker_type
  number_of_workers      = var.number_of_workers
  execution_class        = var.execution_class
  maintenance_window     = var.maintenance_window
  tags                   = local.tags

  command {
    script_location = var.script_location
    name            = var.command_type
  }

  # https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-etl-glue-arguments.html
  default_arguments = merge(local.default_arguments, var.arguments)

  execution_property {
    max_concurrent_runs = var.max_concurrent
  }

  dynamic "notification_property" { ##minutes
    for_each = var.notify_delay_after == null ? [] : [1]

    content {
      notify_delay_after = var.notify_delay_after
    }
  }
}

### Glue Job Service Role
resource "aws_iam_role" "glue-service-role" {
  count = var.create_role && var.create_job ? 1 : 0
  name  = "${var.name}-glue-role"
  tags  = local.tags
  path  = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "glue.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

data "aws_iam_policy_document" "extra-policy-document" {
  #checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions. TO DO Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  #checkov:skip=CKV_AWS_110: "Ensure IAM policies does not allow privilege escalation"

  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetObjectAcl",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetBucketLocation",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.project_id}-*/*",
      "arn:aws:s3:::${var.project_id}-*"
    ]
  }
  # https://docs.aws.amazon.com/glue/latest/dg/monitor-continuous-logging-enable.html#monitor-continuous-logging-encrypt-log-data
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:AssociateKmsKey"
    ]
    resources = [
      "arn:aws:logs:*:*:/aws-glue/*"
    ]
  }
  statement {
    actions = [
      "glue:*",
      "iam:ListRolePolicies",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "cloudwatch:PutMetricData",
      "sqs:*" # Needs Fixing
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "dms:DescribeTableStatistics",
      "dms:DescribeReplicationTasks",
      "dms:StopReplicationTask"
    ]
    resources = [
      "arn:aws:dms:${var.region}:${var.account}:*:*"
    ]
  }
  statement {
    actions = [
      "kinesis:DescribeLimits",
      "kinesis:DescribeStream",
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:SubscribeToShard",
      "kinesis:ListShards"
    ]
    resources = [
      "arn:aws:kinesis:${var.region}:${var.account}:stream/${var.project_id}-*"
    ]
  }
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = concat(var.additional_secret_arns, [
      "arn:aws:secretsmanager:${var.region}:${var.account}:secret:${var.project_id}-redshift-secret-*",
      "arn:aws:secretsmanager:${var.region}:${var.account}:secret:external/${var.project_id}-dps-*"
    ])
  }
  statement {
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      "arn:aws:kms:*:${var.account}:key/*"
    ]
  }
  statement {
    actions = [
      "dynamodb:BatchGet*",
      "dynamodb:DescribeStream",
      "dynamodb:DescribeTable",
      "dynamodb:Get*",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWrite*",
      "dynamodb:CreateTable",
      "dynamodb:Delete*",
      "dynamodb:Update*",
      "dynamodb:PutItem"
    ]
    resources = [
      "arn:aws:dynamodb:${var.region}:${var.account}:table/dpr-*"
    ]
  }
}

resource "aws_iam_policy" "additional-policy" {
  count = var.create_role && var.create_job ? 1 : 0

  name        = "${var.name}-policy"
  description = "Extra Policy for AWS Glue Job"
  policy      = data.aws_iam_policy_document.extra-policy-document.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "glue_policies" {
  for_each = var.create_role ? toset([
    try("arn:aws:iam::${var.account}:policy/${aws_iam_policy.additional-policy[0].name}", null),
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  ]) : []

  role       = var.create_job ? join("", aws_iam_role.glue-service-role.*.name) : var.role_name
  policy_arn = each.value
}

resource "aws_cloudwatch_log_group" "job" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS, Skipping for Timebeing in view of Cost Savings”

  count = var.create_job ? 1 : 0

  name              = "/aws-glue/jobs/${var.name}"
  retention_in_days = var.log_group_retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "sec_config" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS, Skipping for Timebeing in view of Cost Savings”

  count = var.create_job ? 1 : 0

  name              = "/aws-glue/jobs/${var.short_name}-sec-config"
  retention_in_days = var.log_group_retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "sec_config_error" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS, Skipping for Timebeing in view of Cost Savings”

  count = var.create_job ? 1 : 0

  name              = "/aws-glue/jobs/${var.short_name}-sec-config-role/${var.name}-glue-role/error"
  retention_in_days = var.log_group_retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "sec_config_output" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS, Skipping for Timebeing in view of Cost Savings”

  count = var.create_job ? 1 : 0

  name              = "/aws-glue/jobs/${var.short_name}-sec-config-role/${var.name}-glue-role/output"
  retention_in_days = var.log_group_retention_in_days
  tags              = var.tags
}


resource "aws_cloudwatch_log_group" "continuous_log" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS, Skipping for Timebeing in view of Cost Savings”

  count = var.create_job ? 1 : 0

  name              = "/aws-glue/jobs/${var.name}-${var.short_name}-sec-config"
  retention_in_days = var.log_group_retention_in_days
  tags              = var.tags
}

resource "aws_glue_security_configuration" "sec_cfg" {
  #checkov:skip=CKV_AWS_99: "Ensure Glue Security Configuration Encryption is enabled. TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"

  count = var.create_security_configuration && var.create_job ? 1 : 0
  name  = "${var.short_name}-sec-config"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      kms_key_arn        = var.aws_kms_key
      s3_encryption_mode = "SSE-KMS"
    }
  }
}