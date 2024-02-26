# Set a predefined baseline if specified, otherwise set a custom baseline
resource "aws_ssm_default_patch_baseline" "this" {
  baseline_id      = var.use_predefined_baseline == true ? data.aws_ssm_patch_baseline.predefined[0].id : aws_ssm_patch_baseline.baseline-custom[0].id
  operating_system = "WINDOWS"
}

data "aws_ssm_patch_baseline" "predefined" {
  count            = var.use_predefined_baseline == true ? 1 : 0
  owner            = "AWS"
  name_prefix      = var.predefined_baseline
  operating_system = "WINDOWS"
}

resource "aws_ssm_patch_baseline" "baseline-custom" {
  count            = var.use_predefined_baseline == false ? 1 : 0
  name             = "MOJ-CustomBaseline-${var.application}-${var.environment}"
  description      = "Custom Patch Baseline for ${var.application}-${var.environment}"
  operating_system = "WINDOWS"
  approved_patches = var.approved_patches
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
  description   = "${var.application}-${var.environment}} target"

  targets {
    key    = "tag:environment-name"
    values = ["${var.application}-${var.environment}"]
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.application}-${var.environment}-patch-logs"
  retention_in_days = 30
}

resource "aws_ssm_maintenance_window_task" "this" {
  description     = "Maintenance window task for ${var.application}-${var.environment}"
  task_type       = "RUN_COMMAND"
  task_arn        = "AWS-RunPatchBaseline"
  priority        = 1
  max_concurrency = "1" # Patch one instance at a time
  max_errors      = "0" # Stop after the first error result

  cutoff_behavior = "CONTINUE_TASK"

  window_id = aws_ssm_maintenance_window.this.id
  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.this.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      comment          = "Windows Patch Baseline Install"
      document_version = "$LATEST"
      timeout_seconds  = 3600
      cloudwatch_config {
        cloudwatch_log_group_name = aws_cloudwatch_log_group.this.id
        cloudwatch_output_enabled = true
      }
      parameter {
        name   = "Operation"
        values = ["Install"]
      }
    }
  }
}