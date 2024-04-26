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
    approve_after_days  = 5
    enable_non_security = false

    patch_filter {
      key    = "PRODUCT"
      values = ["AmazonLinux2"]
    }
    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security", "Bugfix"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important", "Medium"]
    }
  }
}



# Create Maintenance Windows
# Production Linux
# Fourth Wednesday of the month at 20:00

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
  priority         = 10
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

# Maintenance Window Pre Health Check Task for Linux

resource "aws_ssm_maintenance_window_task" "pre_lin_healthcheck_maintenance_window_task" {
  count            = local.is-production == true ? 1 : 0
  window_id        = aws_ssm_maintenance_window.prod_lin_patch_maintenance_window[0].id
  name             = "Pre-Health-Check-Report-Instance-Patch"
  description      = "Export Health Check Report to S3"
  task_type        = "RUN_COMMAND"
  task_arn         = aws_ssm_document.linux_health_check_s3[0].arn
  priority         = local.application_data.accounts[local.environment].pre_healthcheck_Priority
  service_role_arn = aws_iam_role.patching_role.arn
  max_concurrency  = "100%"
  max_errors       = 0

  targets {
    key    = "WindowTargetIds"
    values = aws_ssm_maintenance_window_target.prod_lin_maintenance_window_target[0].*.id
  }

  task_invocation_parameters {
    run_command_parameters {
      output_s3_bucket     = aws_s3_bucket.MoJ-Health-Check-Reports.id
      output_s3_key_prefix = "ssm_output/"
      timeout_seconds      = 600
    }
  }
}

# Maintenance Window Post Health Check Task for Linux

resource "aws_ssm_maintenance_window_task" "post_lin_healthcheck_maintenance_window_task" {
  count            = local.is-production == true ? 1 : 0
  window_id        = aws_ssm_maintenance_window.prod_lin_patch_maintenance_window[0].id
  name             = "Post-Health-Check-Report-Instance-Patch"
  description      = "Export Health Check Report to S3"
  task_type        = "RUN_COMMAND"
  task_arn         = aws_ssm_document.linux_health_check_s3[0].arn
  priority         = local.application_data.accounts[local.environment].post_healthcheck_Priority
  service_role_arn = aws_iam_role.patching_role.arn
  max_concurrency  = "100%"
  max_errors       = 0

  targets {
    key    = "WindowTargetIds"
    values = aws_ssm_maintenance_window_target.prod_lin_maintenance_window_target[0].*.id
  }

  task_invocation_parameters {
    run_command_parameters {
      output_s3_bucket     = aws_s3_bucket.MoJ-Health-Check-Reports.id
      output_s3_key_prefix = "ssm_output/"
      timeout_seconds      = 600
    }
  }
}


# Create perform_healthcheck_S3 document

resource "aws_ssm_document" "linux_health_check_s3" {
  count         = local.is-production == true ? 1 : 0
  name          = "linux_health_check"
  document_type = "Command"
  content = jsonencode(
    {
      "schemaVersion" = "2.2",
      "description"   = "Execute Shell Command",
      "mainSteps" = [
        {
          "action" = "aws:runShellScript",
          "name"   = "linux_health_check",
          "inputs" = {
            "runCommand" = ["/usr/local/bin/Linux_Health_Check.sh"]
          }
        }
      ]
    }
  )
}
