# Create Patch Group
# PROD LINUX
# Linux instances only exist in production but using the local.environment variable allows
# for future linux instances to be added into dev and uat with their own patch groups



resource "aws_ssm_patch_group" "lin_patch_group" {
  count       = local.is-production == true ? 1 : 0
  baseline_id = aws_ssm_patch_baseline.linux_os_baseline[0].id
  patch_group = local.application_data.accounts[local.environment].lin_patch_group
}

# Create Linux Patch Baseline

resource "aws_ssm_patch_baseline" "linux_os_baseline" {
  count            = local.is-production == true ? 1 : 0
  name             = "LinuxOS"
  description      = "Patch Linux OS"
  operating_system = "AMAZON_LINUX_2"

  approval_rule {
    approve_after_days  = 14
    enable_non_security = false

    patch_filter {
      key    = "PRODUCT"
      values = ["AmazonLinux2"]
    }
    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important", "Medium"]
    }
  }
}



# Create Maintenance Windows
# Production Linux
# second Monday of the month at 20:00

resource "aws_ssm_maintenance_window" "prod_lin_patch_maintenance_window" {
  count             = local.is-production == true ? 1 : 0
  name              = local.application_data.accounts[local.environment].patch_lin_maintenance_window_name
  schedule          = local.application_data.accounts[local.environment].patch_lin_maintenance_schedule_cron
  duration          = local.application_data.accounts[local.environment].patch_lin_maintenance_window_duration
  cutoff            = 1
  schedule_timezone = "Europe/London"
}

resource "aws_ssm_maintenance_window_target" "prod_lin_maintenance_window_target" {
  count         = local.is-production == true ? 1 : 0
  window_id     = aws_ssm_maintenance_window.prod_lin_patch_maintenance_window[0].id
  name          = local.application_data.accounts[local.environment].maintenance_lin_window_target_name
  description   = local.application_data.accounts[local.environment].maintenance_lin_window_target_description
  resource_type = "INSTANCE"

  targets {
    key    = "tag:patch_group"
    values = [aws_ssm_patch_group.lin_patch_group[0].patch_group]
  }
}

# Create Maintenance Window Task
# PROD LINUX

resource "aws_ssm_maintenance_window_task" "prod_lin_patch_maintenance_window_task" {
  count            = local.is-production == true ? 1 : 0
  window_id        = aws_ssm_maintenance_window.prod_lin_patch_maintenance_window[0].id
  name             = local.application_data.accounts[local.environment].maintenance_lin_window_task_name
  description      = "Apply patch management"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline" # linux_os_baseline
  priority         = 1
  service_role_arn = aws_iam_role.patching_role.arn
  max_concurrency  = "15"
  max_errors       = "1"

  targets {
    key    = "WindowTargetIds"
    values = aws_ssm_maintenance_window_target.prod_lin_maintenance_window_target[0].*.id
  }
  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "Operation"
        values = ["Install"]
      }
      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }
    }
  }
}