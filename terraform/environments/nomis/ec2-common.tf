#------------------------------------------------------------------------------
# Session Manager Logging and Settings
#------------------------------------------------------------------------------

resource "aws_ssm_document" "session_manager_settings" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode(
    {
      schemaVersion = "1.0"
      description   = "Document to hold regional settings for Session Manager"
      sessionType   = "Standard_Stream",
      inputs = {
        cloudWatchLogGroupName      = "session-manager-logs"
        cloudWatchEncryptionEnabled = false
        cloudWatchStreamingEnabled  = true
        s3BucketName                = ""
        s3KeyPrefix                 = ""
        s3EncryptionEnabled         = false
        idleSessionTimeout          = "20"
        kmsKeyId                    = "" # aws_kms_key.session_manager.arn
        runAsEnabled                = false
        runAsDefaultUser            = ""
        shellProfile = {
          windows = ""
          linux   = ""
        }
      }
    }
  )
}


#------------------------------------------------------------------------------
# Cloud Watch Agent
#------------------------------------------------------------------------------

resource "aws_ssm_document" "cloud_watch_agent" {
  name            = "InstallAndManageCloudWatchAgent"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/install-and-manage-cwagent.yaml")

  tags = merge(
    local.tags,
    {
      Name = "install-and-manage-cloud-watch-agent"
    },
  )
}

/* resource "aws_ssm_association" "manage_cloud_watch_agent_linux" {
  name             = aws_ssm_document.cloud_watch_agent.name
  association_name = "manage-cloud-watch-agent"
  parameters = { # name of ssm parameter containing cloud watch agent config file
    optionalConfigurationLocation = aws_ssm_parameter.cloud_watch_config_linux.name
  }
  targets {
    key    = "tag:os_type"
    values = ["Linux"]
  }
  apply_only_at_cron_interval = false
  schedule_expression         = "cron(45 7 ? * TUE *)"
} */

resource "aws_ssm_parameter" "cloud_watch_config_linux" {
  #checkov:skip=CKV2_AWS_34:there should not be anything secret in this config
  description = "cloud watch agent config for linux"
  name        = "cloud-watch-config-linux"
  type        = "String"
  value       = file("./templates/cloud_watch_linux.json")

  tags = merge(
    local.tags,
    {
      Name = "cloud-watch-config-linux"
    },
  )
}

resource "aws_ssm_parameter" "cloud_watch_config_windows" {
  #checkov:skip=CKV2_AWS_34:there should not be anything secret in this config
  description = "cloud watch agent config for windows"
  name        = "cloud-watch-config-windows"
  type        = "String"
  value       = file("./templates/cloud_watch_windows.json")

  tags = merge(
    local.tags,
    {
      Name = "cloud-watch-config-windows"
    },
  )
}

#------------------------------------------------------------------------------
# SSM Agent - update Systems Manager Agent
#------------------------------------------------------------------------------

resource "aws_ssm_association" "update_ssm_agent" {
  name             = "AWS-UpdateSSMAgent" # this is an AWS provided document
  association_name = "update-ssm-agent"
  parameters = {
    allowDowngrade = "false"
  }
  targets {
    # we could just target all instances, but this would also include the bastion, which gets rebuilt everyday
    key    = "tag:os_type"
    values = ["Linux", "Windows"]
  }
  apply_only_at_cron_interval = false
  schedule_expression         = "cron(30 7 ? * TUE *)"
}

#------------------------------------------------------------------------------
# Patch Management - Run Ansible Roles manually from SSM document
#------------------------------------------------------------------------------

resource "aws_ssm_document" "run_ansible_patches" {
  name            = "RunAnsiblePatches"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/run-ansible-patches.yaml")
  target_type     = "/AWS::EC2::Instance"

  tags = merge(
    local.tags,
    {
      Name = "run-ansible-patches"
    },
  )
}


#------------------------------------------------------------------------------
# Patch Manager
#------------------------------------------------------------------------------

# Define a Maintenance Window, 2am on patch_day, 180 minutes
resource "aws_ssm_maintenance_window" "maintenance" {
  name                       = "weekly-patching"
  description                = "Maintenance window for applying OS patches"
  schedule                   = "cron(0 2 ? * ${local.environment_config.ec2_common.patch_day} *)"
  duration                   = 3
  cutoff                     = 1
  enabled                    = true
  allow_unassociated_targets = true
  tags = merge(
    local.tags,
    {
      Name = "weekly-patching"
    },
  )
}

# Maintenance window task to apply RHEL patches
resource "aws_ssm_maintenance_window_target" "rhel_patching" {
  window_id     = aws_ssm_maintenance_window.maintenance.id
  name          = "rhel-patching"
  description   = "Target group for RHEL patching"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Patch Group"
    values = [aws_ssm_patch_group.rhel.patch_group]
  }
}

resource "aws_ssm_maintenance_window_task" "rhel_patching" {
  name            = "RHEL-security-patching"
  description     = "Applies AWS default patch baseline for RHEL instances"
  max_concurrency = "100%"
  max_errors      = "50%"
  cutoff_behavior = "CANCEL_TASK"
  priority        = 2
  task_arn        = "AWS-RunPatchBaseline"
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.maintenance.id

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.rhel_patching.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "Operation"
        values = ["Install"]
      }
      parameter {
        name   = "RebootOption"
        values = ["NoReboot"]
      }
    }
  }
}

# Maintenance window task to apply Windows patches
resource "aws_ssm_maintenance_window_target" "windows_patching" {
  window_id     = aws_ssm_maintenance_window.maintenance.id
  name          = "windows-patching"
  description   = "Target group for Windows patching"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Patch Group"
    values = [aws_ssm_patch_group.windows.patch_group]
  }
}

resource "aws_ssm_maintenance_window_task" "windows_patching" {
  name            = "Windows-security-patching"
  description     = "Applies AWS default patch baseline for Windows instances"
  max_concurrency = "100%"
  max_errors      = "50%"
  cutoff_behavior = "CANCEL_TASK"
  priority        = 2
  task_arn        = "AWS-RunPatchBaseline"
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.maintenance.id

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.windows_patching.id]
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

# Patch Baselines
resource "aws_ssm_patch_baseline" "rhel" {
  name             = "USER-RedHatPatchBaseline"
  description      = "Approves all RHEL operating system patches that are classified as Security and Bugfix and that have a severity of Critical or Important."
  operating_system = "REDHAT_ENTERPRISE_LINUX"

  approval_rule {
    approve_after_days = local.environment_config.ec2_common.patch_approval_delay_days
    compliance_level   = "CRITICAL"
    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security"]
    }
    patch_filter {
      key    = "SEVERITY"
      values = ["Critical"]
    }
  }

  approval_rule {
    approve_after_days = local.environment_config.ec2_common.patch_approval_delay_days
    compliance_level   = "HIGH"
    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security"]
    }
    patch_filter {
      key    = "SEVERITY"
      values = ["Important"]
    }
  }

  approval_rule {
    approve_after_days = local.environment_config.ec2_common.patch_approval_delay_days
    compliance_level   = "MEDIUM"
    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Bugfix"]
    }
  }
  tags = merge(
    local.tags,
    {
      Name = "rhel-patch-baseline"
    },
  )
}

resource "aws_ssm_patch_baseline" "windows" {
  name             = "USER-WindowsPatchBaseline-OS"
  description      = "Approves all Windows Server operating system patches that are classified as CriticalUpdates or SecurityUpdates and that have an MSRC severity of Critical or Important."
  operating_system = "WINDOWS"

  approval_rule {
    approve_after_days = local.environment_config.ec2_common.patch_approval_delay_days
    compliance_level   = "CRITICAL"
    patch_filter {
      key    = "CLASSIFICATION"
      values = ["CriticalUpdates", "SecurityUpdates"]
    }
    patch_filter {
      key    = "MSRC_SEVERITY"
      values = ["Critical"]
    }
  }

  approval_rule {
    approve_after_days = local.environment_config.ec2_common.patch_approval_delay_days
    compliance_level   = "HIGH"
    patch_filter {
      key    = "CLASSIFICATION"
      values = ["CriticalUpdates", "SecurityUpdates"]
    }
    patch_filter {
      key    = "MSRC_SEVERITY"
      values = ["Important"]
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "windows-patch-baseline"
    },
  )
}

# Patch Groups
resource "aws_ssm_patch_group" "rhel" {
  baseline_id = aws_ssm_patch_baseline.rhel.id
  patch_group = "RHEL"
}

resource "aws_ssm_patch_group" "windows" {
  baseline_id = aws_ssm_patch_baseline.windows.id
  patch_group = "Windows"
}
# CloudWatch Monitoring Role and Policies

data "aws_iam_policy_document" "cloud-platform-monitoring-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::754256621582:root"]
    }
  }
}

resource "aws_iam_role" "cloudwatch-datasource-role" {
  name               = "CloudwatchDatasourceRole"
  assume_role_policy = data.aws_iam_policy_document.cloud-platform-monitoring-assume-role.json
  tags = merge(
    local.tags,
    {
      Name = "cloudwatch-datasource-role"
    },
  )

}

data "aws_iam_policy_document" "cloudwatch_datasource" {
  statement {
    sid    = "AllowReadingMetricsFromCloudWatch"
    effect = "Allow"
    actions = [
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetInsightRuleReport"
    ]
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = ["*"]
  }
  statement {
    sid    = "AllowReadingLogsFromCloudWatch"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:GetLogGroupFields",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:GetQueryResults",
      "logs:GetLogEvents"
    ]
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = ["*"]
  }
  statement {
    sid    = "AllowReadingTagsInstancesRegionsFromEC2"
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowReadingResourcesForTags"
    effect = "Allow"
    actions = [
      "tag:GetResources"
    ]
    resources = ["*"]
  }

}

resource "aws_iam_policy" "cloudwatch_datasource_policy" {
  name        = "cloudwatch-datasource-policy"
  path        = "/"
  description = "Policy for the Monitoring Cloudwatch Datasource"
  policy      = data.aws_iam_policy_document.cloudwatch_datasource.json
  tags = merge(
    local.tags,
    {
      Name = "cloudwatch-datasource-policy"
    },
  )
}

resource "aws_iam_role_policy_attachment" "cloudwatch_datasource_policy_attach" {
  policy_arn = aws_iam_policy.cloudwatch_datasource_policy.arn
  role       = aws_iam_role.cloudwatch-datasource-role.name

}

