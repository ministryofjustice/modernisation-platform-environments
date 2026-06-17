resource "aws_kinesisanalyticsv2_application" "managed_apache_flink_application" {
  name                   = lower(var.config_property_group.app_name)
  runtime_environment    = var.config_property_group.runtime_environment
  service_execution_role = aws_iam_role.managed_apache_flink_application.arn

  cloudwatch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.flink_log_stream.arn
  }

  application_configuration {
    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn     = data.aws_s3_bucket.source_bucket.arn
          file_key       = aws_s3_object.source_bucket.key
          object_version = aws_s3_object.source_bucket.version_id
        }
      }
      code_content_type = "ZIPFILE"
    }

    environment_properties {
      property_group {
        property_group_id = "config"
        property_map      = var.config_property_group.custom_property_group
      }
      property_group {
        property_group_id = "job"
        property_map      = var.config_property_group.job_property_group
      }
    }

    application_snapshot_configuration {
      snapshots_enabled = var.config_property_group.snapshots_enabled
    }

    vpc_configuration {
      subnet_ids         = var.private_subnets
      security_group_ids = var.vpc_security_groups
    }

    flink_application_configuration {
      checkpoint_configuration {
        configuration_type            = var.config_property_group.checkpointing_type
        checkpointing_enabled         = var.config_property_group.checkpointing_enabled
        checkpoint_interval           = var.config_property_group.checkpoint_interval
        min_pause_between_checkpoints = var.config_property_group.min_pause_between_checkpoints
      }

      monitoring_configuration {
        configuration_type = var.config_property_group.monitoring_type
        log_level          = var.config_property_group.log_level
        metrics_level      = "TASK"
      }

      parallelism_configuration {
        auto_scaling_enabled = var.config_property_group.auto_scaling_enabled
        configuration_type   = var.config_property_group.parallelism_type
        parallelism          = var.config_property_group.parallelism
        parallelism_per_kpu  = var.config_property_group.parallelism_per_kpu
      }
    }
  }

  depends_on = [aws_s3_object.source_bucket]
}