##########################################################################################
# SSM Patch Management Groups, Baselines, Maintenance Windows and Maintenance Window Tasks
##########################################################################################

# SSM Patch Groups - All Environments

resource "aws_ssm_patch_group" "win_patch_group" {
  baseline_id = aws_ssm_patch_baseline.windows_os_apps_baseline.id
  patch_group = local.application_data.accounts[local.environment].patch_group
}

# SSM Windows Patch Baseline - All Environments

resource "aws_ssm_patch_baseline" "windows_os_apps_baseline" {
  name             = "WindowsOSAndMicrosoftApps"
  description      = "Patch both Windows and Microsoft apps"
  operating_system = "WINDOWS"
  approved_patches = ["KB890830"] # Malicious Software Removal Tool

  approval_rule {
    approve_after_days = 5

    patch_filter {
      key    = "PRODUCT"
      values = ["WindowsServer2022"]
    }
    patch_filter {
      key    = "CLASSIFICATION"
      values = ["CriticalUpdates", "SecurityUpdates", "Updates", "UpdateRollups", "DefinitionUpdates"]
    }
    patch_filter {
      key    = "MSRC_SEVERITY"
      values = ["Critical", "Important", "Moderate", "Low", "Unspecified"]
    }
  }

  approval_rule {
    approve_after_days = 5
    patch_filter {
      key    = "PATCH_SET"
      values = ["APPLICATION"]
    }

  }
}

# SSM Maintenance Windows - All Environments
# Configuration for each environment is in the application_variables.json file

# Development : Third Tuesday of the month at 17:00 UTC / 18:00 BST
# UAT:          Third Tuesday of the month at 17:00 UTC / 18:00 BST
# Production:   Fourth Tuesday of the month at 19:00 UTC / 20:00 BST

resource "aws_ssm_maintenance_window" "patch_maintenance_window" {
  name              = local.application_data.accounts[local.environment].patch_maintenance_window_name
  schedule          = local.application_data.accounts[local.environment].patch_maintenance_schedule_cron
  duration          = local.application_data.accounts[local.environment].patch_maintenance_window_duration
  cutoff            = 1
  schedule_timezone = "Europe/London"
}

resource "aws_ssm_maintenance_window_target" "patch_maintenance_window_target" {
  window_id     = aws_ssm_maintenance_window.patch_maintenance_window.id
  name          = local.application_data.accounts[local.environment].maintenance_window_target_name
  description   = local.application_data.accounts[local.environment].maintenance_window_target_description
  resource_type = "INSTANCE"

  targets {
    key    = "tag:patch_group"
    values = [aws_ssm_patch_group.win_patch_group.patch_group]
  }
}

# SSM Maintenance Window Task Patch Baseline - All Environments

resource "aws_ssm_maintenance_window_task" "patch_maintenance_window_task" {
  window_id        = aws_ssm_maintenance_window.patch_maintenance_window.id
  name             = local.application_data.accounts[local.environment].maintenance_window_task_name
  description      = "Apply patch management"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline" # windows_os_apps_baseline 
  priority         = 10
  service_role_arn = aws_iam_role.patching_role.arn
  max_concurrency  = "15"
  max_errors       = "2"

  targets {
    key    = "WindowTargetIds"
    values = aws_ssm_maintenance_window_target.patch_maintenance_window_target.*.id
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

# SSM Maintenance Window Task Pre Patch Health Check - All Environments

resource "aws_ssm_maintenance_window_task" "pre_healthcheck_maintenance_window_task" {
  window_id        = aws_ssm_maintenance_window.patch_maintenance_window.id
  name             = "Pre-Health-Check-Report-Instance-Patch"
  description      = "Export Health Check Report to S3"
  task_type        = "RUN_COMMAND"
  task_arn         = aws_ssm_document.perform_healthcheck_s3.arn
  priority         = local.application_data.accounts[local.environment].pre_healthcheck_Priority
  service_role_arn = aws_iam_role.patching_role.arn
  max_concurrency  = "100%"
  max_errors       = 0

  targets {
    key    = "WindowTargetIds"
    values = aws_ssm_maintenance_window_target.patch_maintenance_window_target.*.id
  }

  task_invocation_parameters {
    run_command_parameters {
      output_s3_bucket     = aws_s3_bucket.MoJ-Health-Check-Reports.id
      output_s3_key_prefix = "health-check-reports/"
      timeout_seconds      = 600
    }
  }
}

# SSM Maintenance Window Task Post Patch Health Check - All Environments

resource "aws_ssm_maintenance_window_task" "post_healthcheck_maintenance_window_task" {
  window_id        = aws_ssm_maintenance_window.patch_maintenance_window.id
  name             = "Post-Health-Check-Report-Instance-Patch"
  description      = "Export Health Check Report to S3"
  task_type        = "RUN_COMMAND"
  task_arn         = aws_ssm_document.perform_healthcheck_s3.arn
  priority         = local.application_data.accounts[local.environment].post_healthcheck_Priority
  service_role_arn = aws_iam_role.patching_role.arn
  max_concurrency  = "100%"
  max_errors       = 0

  targets {
    key    = "WindowTargetIds"
    values = aws_ssm_maintenance_window_target.patch_maintenance_window_target.*.id
  }

  task_invocation_parameters {
    run_command_parameters {
      output_s3_bucket     = aws_s3_bucket.MoJ-Health-Check-Reports.id
      output_s3_key_prefix = "health-check-reports/"
      timeout_seconds      = 600
    }
  }
}

# SSM Document for Healthcheck Report (to S3 Bucket) - All Environments

resource "aws_ssm_document" "perform_healthcheck_s3" {
  name          = "perform_health_check"
  document_type = "Command"
  content = jsonencode(
    {
      "schemaVersion" = "2.2",
      "description"   = "Execute Powershell Command",
      "mainSteps" = [
        {
          "action" = "aws:runPowerShellScript",
          "name"   = "health_check_reports",
          "inputs" = {
            "runCommand" = ["powershell.exe -file 'c:\\scripts\\windows_health_check.ps1'"]
          }
        }
      ]
    }
  )
}
