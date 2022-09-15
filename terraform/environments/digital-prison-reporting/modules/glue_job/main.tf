locals {
  default_arguments = {
    "--job-language"                      = "${var.language}"
    "--job-bookmark-option"               = "${lookup(var.bookmark_options, var.bookmark)}"
    "--TempDir"                           = "${var.temp_dir}"
    "--continuous-log-logGroup"           = aws_cloudwatch_log_group.example.name
    "--enable-continuous-cloudwatch-log"  = "true"
    "--enable-continuous-log-filter"      = "true"
    "--continuous-log-logStreamPrefix"    = var.continuous_log_stream_prefix
  }
}

resource "aws_glue_job" "glue_job" {
  count = "${var.create_job ? 1 : 0}"

  name                   = "${var.name}"
  role_arn               = var.create_role ? join("", aws_iam_role.role.*.arn) : var.role_arn
  connections            = ["${var.connections}"]
  allocated_capacity     = "${var.dpu}"
  description            = var.description
  glue_version           = var.glue_version
  max_retries            = var.max_retries
  timeout                = var.timeout
  security_configuration = var.create_security_configuration ? join("", aws_glue_security_configuration.sec_cfg.*.id) : var.security_configuration
  worker_type            = var.worker_type
  number_of_workers      = var.number_of_workers
  tags                   = local.tags

  command {
    script_location = "${var.script_location}"
  }

  # https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-etl-glue-arguments.html
  default_arguments = "${merge(local.default_arguments, var.arguments)}"

  description = "${var.description}"
  max_retries = "${var.max_retries}"
  timeout     = "${var.timeout}"

  execution_property {
    max_concurrent_runs = "${var.max_concurrent}"
  }

    dynamic "notification_property" { ##minutes
    for_each = var.notify_delay_after == null ? [] : [1]

    content {
      notify_delay_after = var.notify_delay_after
    }
  }
}

resource "aws_iam_role" "role" {
  count = var.create_role ? 1 : 0
  name  = "${local.full_name}-role"
  tags  = local.tags

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = [
          "sts:AssumeRole"
        ]
        Principal = {
          "Service" = "glue.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  ]
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws-glue/jobs/${local.full_name}"
  retention_in_days = var.log_group_retention_in_days
  tags              = var.tags
}

resource "aws_glue_security_configuration" "sec_cfg" {
  count = var.create_security_configuration ? 1 : 0
  name  = "${local.full_name}-sec-config"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      kms_key_arn        = data.aws_kms_key.example.arn
      s3_encryption_mode = "SSE-KMS"
    }
  }
  }
}