# Create Patch Group
# DEV, UAT and PROD

resource "aws_ssm_patch_group" "win_patch_group" {
  baseline_id = aws_ssm_patch_baseline.windows_os_apps_baseline.id
  patch_group = local.application_data.accounts[local.environment].patch_group
}

# Create Patch Baseline
# All environments

resource "aws_ssm_patch_baseline" "windows_os_apps_baseline" {
  name             = "WindowsOSAndMicrosoftApps"
  description      = "Patch both Windows and Microsoft apps"
  operating_system = "WINDOWS"

  approval_rule {
    approve_after_days = 14

  patch_filter {
      key    = "PRODUCT"
      values = ["WindowsServer2012", "WindowsServer2016", "WindowsServer2019", "WindowsServer2022"]
    }
    patch_filter {
      key    = "CLASSIFICATION"
      values = ["CriticalUpdates", "SecurityUpdates"]
    }

    patch_filter {
      key    = "MSRC_SEVERITY"
      values = ["Critical", "Important", "Moderate"]
    }
  }

  approval_rule {
    approve_after_days = 14

    patch_filter {
      key    = "PATCH_SET"
      values = ["APPLICATION"]
    }

    # Filter on Microsoft product if necessary
    patch_filter {
      key    = "PRODUCT"
      values = ["Office2003", "Office2007", "Office2010", "Office 2013", "Office 2016", "Office2019", "Office2021"]
    }
  }
}


# Create Maintenance Windows

# Development
# first Monday of the month at 18:00

resource "aws_ssm_maintenance_window" "dev_patch_maintenance_window" {
  count    = local.is-development == true ? 1 : 0
  name     = "dev_patch_maintenance_window"
  schedule = "cron(0 18 ? * 2#1 *)"
  duration = 3
  cutoff   = 1
}

resource "aws_ssm_maintenance_window_target" "dev_patch_maintenance_window_target" {
  count         = local.is-development == true ? 1 : 0
  window_id     = aws_ssm_maintenance_window.dev_patch_maintenance_window[0].id
  name          = "development_maintenance_window_target"
  description   = "This is the dev patch maintenance window target"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:patch_group"
    values = [aws_ssm_patch_group.dev_win_patch.patch_group]
  }
}

# UAT
# first Tuesday of the month at 18:00

resource "aws_ssm_maintenance_window" "uat_patch_maintenance_window" {
  count    = local.is-preproduction == true ? 1 : 0
  name     = "uat_patch_maintenance_window"
  schedule = "cron(0 18 ? * 3#1 *)"
  duration = 3
  cutoff   = 1
}

resource "aws_ssm_maintenance_window_target" "uat_patch_maintenance_window_target" {
  count         = local.is-preproduction == true ? 1 : 0
  window_id     = aws_ssm_maintenance_window.uat_patch_maintenance_window[0].id
  name          = "uat_patch_maintenance_window_target"
  description   = "This is the uat patch maintenance window target"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:patch_group"
    values = [aws_ssm_patch_group.uat_win_patch.patch_group]
  }
}

# Production
# second Tuesday of the month at 20:00

resource "aws_ssm_maintenance_window" "prod_patch_maintenance_window" {
  count    = local.is-production == true ? 1 : 0
  name     = "prod_patch_maintenance_window"
  schedule = "cron(0 20 ? * 3#2 *)"
  duration = 4
  cutoff   = 1
}

resource "aws_ssm_maintenance_window_target" "prod_maintenance_window_target" {
  count         = local.is-production == true ? 1 : 0
  window_id     = aws_ssm_maintenance_window.prod_patch_maintenance_window[0].id
  name          = "prod_patch_maintenance_window_target"
  description   = "This is the production patch maintenance window target"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:patch_group"
    values = [aws_ssm_patch_group.prod_win_patch.patch_group]
  }
}


# Create Maintenance Window Task

# Dev

resource "aws_ssm_maintenance_window_task" "dev_patch_maintenance_window_task" {
  count            = local.is-development == true ? 1 : 0
  window_id        = aws_ssm_maintenance_window.dev_patch_maintenance_window[0].id
  name             = "DEV-Instance-Patch"
  description      = "Apply patch management"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline" # windows_os_apps_baseline
  priority         = 1
  service_role_arn = aws_iam_role.patching_role.arn
  max_concurrency  = "15"
  max_errors       = "1"

  targets {
    key    = "WindowTargetIds"
    values = aws_ssm_maintenance_window_target.dev_patch_maintenance_window_target[0].*.id
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


# UAT

resource "aws_ssm_maintenance_window_task" "uat_patch_maintenance_window_task" {
  count            = local.is-preproduction == true ? 1 : 0
  window_id        = aws_ssm_maintenance_window.uat_patch_maintenance_window[0].id
  name             = "UAT-Instance-Patch"
  description      = "Apply patch management"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline" # windows_os_apps_baseline
  priority         = 1
  service_role_arn = aws_iam_role.patching_role.arn
  max_concurrency  = "15"
  max_errors       = "1"

  targets {
    key    = "WindowTargetIds"
    values = aws_ssm_maintenance_window_target.uat_patch_maintenance_window_target[0].*.id
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

# PROD

resource "aws_ssm_maintenance_window_task" "prod_patch_maintenance_window_task" {
  count            = local.is-production == true ? 1 : 0
  window_id        = aws_ssm_maintenance_window.prod_patch_maintenance_window[0].id
  name             = "Prod-Instance-Patch"
  description      = "Apply patch management"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline" # windows_os_apps_baseline
  priority         = 1
  service_role_arn = aws_iam_role.patching_role.arn
  max_concurrency  = "15"
  max_errors       = "1"

  targets {
    key    = "WindowTargetIds"
    values = aws_ssm_maintenance_window_target.prod_maintenance_window_target[0].*.id
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


# IAM Role for patching

resource "aws_iam_role" "patching_role" {
  name = "maintenance_window_task_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ssm.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach necessary policies to the role
resource "aws_iam_role_policy_attachment" "maintenance_window_task_policy_attachment" {
  role       = aws_iam_role.patching_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}
