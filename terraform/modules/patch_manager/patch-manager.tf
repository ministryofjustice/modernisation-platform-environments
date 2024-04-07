data "aws_ssm_patch_baseline" "predefined" {
  owner            = "AWS"
  name_prefix      = var.predefined_baseline
  operating_system = var.operating_system
}

resource "aws_ssm_default_patch_baseline" "this" {
  baseline_id      = data.aws_ssm_patch_baseline.predefined.id
  operating_system = var.operating_system
}

resource "aws_ssm_maintenance_window" "this" {
  name        = "${var.application}-${var.environment}-${local.os}-maintenance-window"
  schedule    = var.schedule
  description = "${var.application}-${var.environment}-${local.os} maintenance window"
  duration    = 3
  cutoff      = 1
}

resource "aws_ssm_maintenance_window_target" "this" {
  window_id     = aws_ssm_maintenance_window.this.id
  resource_type = "INSTANCE"
  description   = "${var.application}-${var.environment}-${local.os} target"

  targets {
    key    = "tag:${keys(var.target_tag)[0]}"
    values = [values(var.target_tag)[0]]
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.application}-${var.environment}-${local.os}-patch-logs"
  retention_in_days = 30
}

resource "aws_ssm_maintenance_window_task" "this" {
  description = "Patching task for ${var.application}-${var.environment}-${local.os}"
  task_type   = "RUN_COMMAND"
  # Only development uses AWS-RunPatchBaselineWithHooks to trigger post patching jobs and you can't use this task
  # when specifying exact patches so the environments will run the standard AWS-RunPatchBaseline task
  task_arn        = var.environment == "development" ? "AWS-RunPatchBaselineWithHooks" : "AWS-RunPatchBaseline"
  priority        = 1
  max_concurrency = "2" # Temp values for debugging
  max_errors      = "2" # Temp values for debugging

  cutoff_behavior = "CONTINUE_TASK"

  window_id = aws_ssm_maintenance_window.this.id
  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.this.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      comment              = "Patch Baseline Install"
      document_version     = "$LATEST"
      timeout_seconds      = 3600
      output_s3_bucket     = aws_s3_bucket.patch_logs.id
      output_s3_key_prefix = "patch-logs"
      cloudwatch_config {
        cloudwatch_log_group_name = aws_cloudwatch_log_group.this.name
        cloudwatch_output_enabled = true
      }
      parameter {
        name   = "Operation"
        values = ["Install"]
      }

      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }

      dynamic "parameter" {
        for_each = var.environment == "development" ? [1] : []
        content {
          # Extract successful patches after development gets patched
          name   = "PostInstallHookDocName"
          values = [aws_ssm_document.extract-upload-patches[0].arn]
        }
      }

      # All non-development environments pull patch list from development
      dynamic "parameter" {
        for_each = var.environment != "development" && var.operating_system == "WINDOWS" ? [1] : []
        content {
          name   = "InstallOverrideList"
          values = ["s3://${var.application}-development-${local.os}-patches/WindowsServer2022DatacenterPatches.yaml"]
        }
      }

      dynamic "parameter" {
        for_each = var.environment != "development" && var.operating_system == "REDHAT_ENTERPRISE_LINUX" ? [1] : []
        content {
          name   = "InstallOverrideList"
          values = ["s3://${var.application}-development-${local.os}-patches/RedHatEnterpriseLinux89OotpaPatches.yaml"]
        }
      }
    }
  }
}