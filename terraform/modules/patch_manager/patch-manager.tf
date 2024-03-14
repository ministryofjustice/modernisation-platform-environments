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
  name        = "${var.application}-${var.environment}-maintenance-window"
  schedule    = var.schedule
  description = "Maintenance window for ${var.application}-${var.environment}"
  duration    = 3
  cutoff      = 1
}

resource "aws_ssm_maintenance_window_target" "this" {
  window_id     = aws_ssm_maintenance_window.this.id
  resource_type = "INSTANCE"
  description   = "${var.application}-${var.environment} target"

  targets {
    key    = "tag:${keys(var.target_tag)[0]}"
    values = [values(var.target_tag)[0]]
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.application}-${var.environment}-patch-logs"
  retention_in_days = 30
}

resource "aws_ssm_maintenance_window_task" "this" {
  description     = "Maintenance window task for ${var.application}-${var.environment}"
  task_type       = "RUN_COMMAND"
  # Only development uses AWS-RunPatchBaselineWithHooks to trigger post patching jobs and you can't use this task
  # when specifying exact patches so the environments will run the standard AWS-RunPatchBaseline task
  task_arn        = var.environment == "development" || var.application != "hmpps-domain-services-test-predefined" ? "AWS-RunPatchBaselineWithHooks" : "AWS-RunPatchBaseline"
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
      output_s3_bucket     = aws_s3_bucket.this.id
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
        for_each = var.environment == "development" || var.application != "hmpps-domain-services-test-predefined" ? [1] : []
        content {
          # Extract successful patches after development gets patched
          name   = "PostInstallHookDocName"
          values = [aws_ssm_document.extract-upload-patches[0].arn]
        }
      }

      dynamic "parameter" {
        for_each = var.environment != "development" || var.application != "hmpps-domain-services-test-predefined"  ? [1] : []
        content {
          # All non-development environments pull patch list from development
          name   = "InstallOverrideList"
          values = ["s3://${var.application}-development-patch-logs/windows/WindowsServer2022DatacenterPatches.yaml"]
        }
      }
    }
  }
}