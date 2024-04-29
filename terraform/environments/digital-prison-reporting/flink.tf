locals {
  flink_views_jar_file = "flink-spike-0.26-SNAPSHOT-all.jar"
  flink_jar_bucket_arn = "arn:aws:s3:::flink-demo-771283872747-eu-west-2-1713861000297-bucket"
}

resource "aws_iam_role" "flink_role" {
  name               = "dpr-flink-spike-execution-role-development"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Principal = {
          "Service" = "kinesisanalytics.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "flink_spike_additional_policy" {
  name   = "flink_spike_additional_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:Get*",
          "s3:List*",
          "s3:Put*",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::dpr-working-development",
          "arn:aws:s3:::dpr-working-development/*",
          "arn:aws:s3:::flink-demo-771283872747-eu-west-2-1713861000297-bucket",
          "arn:aws:s3:::flink-demo-771283872747-eu-west-2-1713861000297-bucket/*",
          "arn:aws:s3:::dpr-artifact-store-development",
          "arn:aws:s3:::dpr-artifact-store-development/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:Get*",
          "s3:List*"
        ],
        "Resource" : [
          "arn:aws:s3:::dpr-schema-registry-development",
          "arn:aws:s3:::dpr-schema-registry-development/*",
          "arn:aws:s3:::dpr-raw-archive-development",
          "arn:aws:s3:::dpr-raw-archive-development/*",
          "arn:aws:s3:::dpr-raw-development",
          "arn:aws:s3:::dpr-raw-development/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ],
        "Resource" : [
          "arn:aws:kms:*:${local.account_id}:key/*"
        ]
      },
      {
        "Action" : "cloudwatch:PutMetricData",
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "flink_spike_policy_attachment" {
  role       = aws_iam_role.flink_role.name
  policy_arn = aws_iam_policy.flink_spike_additional_policy.arn
}

resource "aws_iam_role_policy_attachment" "flink_spike_cloudwatch_full_access_policy_attachment" {
  role       = aws_iam_role.flink_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "flink_spike_vpc_full_access_policy_attachment" {
  role       = aws_iam_role.flink_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_security_group" "flink_allow_outbound" {
  name        = "flink_allow_outbound"
  description = "Allow all outbound traffic from the Flink application"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

// Master Summary Batch

resource "aws_cloudwatch_log_group" "flink_master_summary_batch_log_group" {
  name              = "/aws/kinesis-analytics/flink-master-summary-batch"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "flink_master_summary_batch_log_stream" {
  name           = "flink_master_summary_batch"
  log_group_name = aws_cloudwatch_log_group.flink_master_summary_batch_log_group.name
}

resource "aws_kinesisanalyticsv2_application" "master_summary_batch" {
  name                   = "flink-master-summary-batch"
  runtime_environment    = "FLINK-1_18"
  service_execution_role = aws_iam_role.flink_role.arn

  application_configuration {

    application_snapshot_configuration {
      snapshots_enabled = false
    }

    environment_properties {
      property_group {
        property_group_id = "appConfig"
        property_map = {
          "viewName" : "master_summary"
          "mode" : "batch"
        }
      }
    }

    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn = local.flink_jar_bucket_arn
          file_key   = local.flink_views_jar_file
        }
      }

      code_content_type = "ZIPFILE"
    }


    flink_application_configuration {
      checkpoint_configuration {
        configuration_type    = "CUSTOM"
        checkpointing_enabled = false
        checkpoint_interval   = 3600000
      }

      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = "INFO"
        metrics_level      = "APPLICATION"
      }

      parallelism_configuration {
        auto_scaling_enabled = false
        configuration_type   = "CUSTOM"
        parallelism          = 6
        parallelism_per_kpu  = 1
      }
    }

    vpc_configuration {
      security_group_ids = [aws_security_group.flink_allow_outbound.id]
      subnet_ids         = [data.aws_subnet.private_subnets_a.id]
    }
  }

  cloudwatch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.flink_master_summary_batch_log_stream.arn
  }
}

// Master Summary Stream

resource "aws_cloudwatch_log_group" "flink_master_summary_stream_log_group" {
  name              = "/aws/kinesis-analytics/flink-master-summary-stream"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "flink_master_summary_stream_log_stream" {
  name           = "flink_master_summary_stream"
  log_group_name = aws_cloudwatch_log_group.flink_master_summary_stream_log_group.name
}

resource "aws_kinesisanalyticsv2_application" "master_summary_stream" {
  name                   = "flink-master-summary-stream"
  runtime_environment    = "FLINK-1_18"
  service_execution_role = aws_iam_role.flink_role.arn

  application_configuration {

    application_snapshot_configuration {
      snapshots_enabled = true
    }

    environment_properties {
      property_group {
        property_group_id = "appConfig"
        property_map = {
          "viewName" : "master_summary"
          "mode" : "stream"
        }
      }
    }

    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn = local.flink_jar_bucket_arn
          file_key   = local.flink_views_jar_file
        }
      }

      code_content_type = "ZIPFILE"
    }


    flink_application_configuration {
      checkpoint_configuration {
        configuration_type            = "CUSTOM"
        checkpointing_enabled         = true
        checkpoint_interval           = 60000
        min_pause_between_checkpoints = 5000
      }

      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = "INFO"
        metrics_level      = "APPLICATION"
      }

      parallelism_configuration {
        auto_scaling_enabled = true
        configuration_type   = "CUSTOM"
        parallelism          = 1
        parallelism_per_kpu  = 1
      }
    }

    vpc_configuration {
      security_group_ids = [aws_security_group.flink_allow_outbound.id]
      subnet_ids         = [data.aws_subnet.private_subnets_a.id]
    }
  }

  cloudwatch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.flink_master_summary_stream_log_stream.arn
  }
}

// Master Complex Batch

resource "aws_cloudwatch_log_group" "flink_master_complex_batch_log_group" {
  name              = "/aws/kinesis-analytics/flink-master-complex-batch"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "flink_master_complex_batch_log_stream" {
  name           = "master_complex_batch"
  log_group_name = aws_cloudwatch_log_group.flink_master_complex_batch_log_group.name
}

resource "aws_kinesisanalyticsv2_application" "master_complex_batch" {
  name                   = "flink-master-complex-batch"
  runtime_environment    = "FLINK-1_18"
  service_execution_role = aws_iam_role.flink_role.arn

  application_configuration {

    application_snapshot_configuration {
      snapshots_enabled = false
    }

    environment_properties {
      property_group {
        property_group_id = "appConfig"
        property_map = {
          "viewName" : "master_complex"
          "mode" : "batch"
        }
      }
    }

    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn = local.flink_jar_bucket_arn
          file_key   = local.flink_views_jar_file
        }
      }

      code_content_type = "ZIPFILE"
    }

    flink_application_configuration {
      checkpoint_configuration {
        configuration_type    = "CUSTOM"
        checkpointing_enabled = false
        checkpoint_interval   = 3600000
      }

      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = "INFO"
        metrics_level      = "APPLICATION"
      }

      parallelism_configuration {
        auto_scaling_enabled = false
        configuration_type   = "CUSTOM"
        parallelism          = 6
        parallelism_per_kpu  = 1
      }
    }

    vpc_configuration {
      security_group_ids = [aws_security_group.flink_allow_outbound.id]
      subnet_ids         = [data.aws_subnet.private_subnets_a.id]
    }
  }

  cloudwatch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.flink_master_complex_batch_log_stream.arn
  }
}

// Master Complex Streaming

resource "aws_cloudwatch_log_group" "flink_master_complex_stream_log_group" {
  name              = "/aws/kinesis-analytics/flink-master-complex-stream"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "flink_master_complex_stream_log_stream" {
  name           = "master_complex_stream"
  log_group_name = aws_cloudwatch_log_group.flink_master_complex_stream_log_group.name
}

resource "aws_kinesisanalyticsv2_application" "master_complex_stream" {
  name                   = "flink-master-complex-stream"
  runtime_environment    = "FLINK-1_18"
  service_execution_role = aws_iam_role.flink_role.arn

  application_configuration {

    application_snapshot_configuration {
      snapshots_enabled = true
    }

    environment_properties {
      property_group {
        property_group_id = "appConfig"
        property_map = {
          "viewName" : "master_complex"
          "mode" : "stream"
        }
      }
    }

    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn = local.flink_jar_bucket_arn
          file_key   = local.flink_views_jar_file
        }
      }

      code_content_type = "ZIPFILE"
    }

    flink_application_configuration {
      checkpoint_configuration {
        configuration_type            = "CUSTOM"
        checkpointing_enabled         = true
        checkpoint_interval           = 60000
        min_pause_between_checkpoints = 5000
      }

      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = "INFO"
        metrics_level      = "APPLICATION"
      }

      parallelism_configuration {
        auto_scaling_enabled = true
        configuration_type   = "CUSTOM"
        parallelism          = 1
        parallelism_per_kpu  = 1
      }
    }

    vpc_configuration {
      security_group_ids = [aws_security_group.flink_allow_outbound.id]
      subnet_ids         = [data.aws_subnet.private_subnets_a.id]
    }
  }

  cloudwatch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.flink_master_complex_stream_log_stream.arn
  }
}
