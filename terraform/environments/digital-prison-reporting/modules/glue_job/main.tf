locals {
  default_arguments = {
    "--job-language"                     = var.job_language
    "--job-bookmark-option"              = "${lookup(var.bookmark_options, var.bookmark)}"
    "--TempDir"                          = var.temp_dir
    "--checkpoint.location"              = var.checkpoint_dir
    "--spark-event-logs-path"            = var.spark_event_logs
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.log_group.name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-glue-datacatalog"          = "true"
    "--enable-job-insights"              = "true"
    "--continuous-log-logStreamPrefix"   = var.continuous_log_stream_prefix
    "--enable-continuous-log-filter"     = var.enable_continuous_log_filter
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
  timeout                = var.timeout
  execution_class        = var.execution_class
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
#  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"]
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
  statement {
    actions = [
      "s3:*"
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
      "sqs:*"  # Needs Fixing
    ]
    resources = [
      "*"
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
  name        = "${var.name}-policy"
  description = "Extra Policy for AWS Glue Job"
  policy      = data.aws_iam_policy_document.extra-policy-document.json
}

resource "aws_iam_role_policy_attachment" "glue_policies" {
  for_each = toset([
    aws_iam_policy.additional-policy.arn,
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  ])

  role = var.create_role ? join("", aws_iam_role.glue-service-role.*.name) : var.role_name
  policy_arn = each.value

#  policy_arn = aws_iam_policy.additional-policy.arn
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws-glue/jobs/${var.name}-sec-config"
  retention_in_days = var.log_group_retention_in_days
  tags              = var.tags
}

resource "aws_glue_security_configuration" "sec_cfg" {
  count = var.create_security_configuration && var.create_job ? 1 : 0
  name  = "${var.name}-sec-config"

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