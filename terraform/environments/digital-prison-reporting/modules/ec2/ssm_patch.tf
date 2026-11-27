# tflint-ignore-file: terraform_required_version, terraform_required_providers
#
# SSM Patch Manager resources
#
# Two-layer patching strategy:
#   Layer 1 — Maintenance Window (weekly install on Sunday 02:00 UTC)
#   Layer 2 — State Manager Association (weekly compliance scan on Sunday 01:00 UTC)
#
# Instances are linked to this baseline via the "Patch Group" tag, which is
# injected into the launch template tag_specifications block in main.tf.

# ---------------------------------------------------------------------------
# Patch Baseline
# ---------------------------------------------------------------------------
# Two approval rules:
#   1. Security + Bugfix patches (Critical/Important/Medium) — approved after 7 days
#   2. Critical Security patches only                        — approved immediately (0 days)
resource "aws_ssm_patch_baseline" "al2023" {
  name             = "${var.name}-al2023-patch-baseline"
  description      = "Patch baseline for Amazon Linux 2023 bastion EC2 instances"
  operating_system = "AMAZON_LINUX_2023"

  # Rule 1 — General security and bug-fix patches approved after 7-day testing period
  approval_rule {
    approve_after_days = 7
    compliance_level   = "HIGH"

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security", "Bugfix"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important", "Medium"]
    }
  }

  # Rule 2 — Critical security patches approved immediately (zero-day SLA)
  approval_rule {
    approve_after_days = 0
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

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Patch Group
# ---------------------------------------------------------------------------
# Associates this baseline with the "Patch Group" tag value used on instances.
resource "aws_ssm_patch_group" "bastion" {
  baseline_id = aws_ssm_patch_baseline.al2023.id
  patch_group = "${var.name}-patch-group"
}

# ---------------------------------------------------------------------------
# Maintenance Window — weekly Sunday 02:00 UTC, 2-hour window, 1-hour cutoff
# ---------------------------------------------------------------------------
resource "aws_ssm_maintenance_window" "bastion_patch" {
  name        = "${var.name}-patch-window"
  description = "Weekly patching maintenance window for bastion EC2 instances"
  schedule    = "cron(0 2 ? * SUN *)"
  duration    = 2
  cutoff      = 1

  allow_unassociated_targets = false

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Maintenance Window Target — select instances by Patch Group tag
# ---------------------------------------------------------------------------
resource "aws_ssm_maintenance_window_target" "bastion" {
  window_id     = aws_ssm_maintenance_window.bastion_patch.id
  name          = "${var.name}-target"
  description   = "Bastion EC2 instances targeted by Patch Group tag"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Patch Group"
    values = ["${var.name}-patch-group"]
  }
}

# ---------------------------------------------------------------------------
# Maintenance Window Task — runs AWS-RunPatchBaseline (Install + RebootIfNeeded)
# ---------------------------------------------------------------------------
resource "aws_ssm_maintenance_window_task" "patch_bastion" {
  window_id        = aws_ssm_maintenance_window.bastion_patch.id
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = 1
  service_role_arn = aws_iam_role.ssm_maintenance_window_role.arn
  max_concurrency  = "1"
  max_errors       = "1"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.bastion.id]
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

      # Write patch operation output to S3 when a bucket is supplied.
      # Falls back to no S3 logging when patch_logs_s3_bucket is empty.
      output_s3_bucket     = var.patch_logs_s3_bucket != "" ? var.patch_logs_s3_bucket : null
      output_s3_key_prefix = var.patch_logs_s3_bucket != "" ? "ssm-patch-logs/${var.name}/" : null
    }
  }
}

# ---------------------------------------------------------------------------
# State Manager Association — weekly Scan (compliance reporting, no install)
# Runs one hour before the maintenance window so compliance status is current.
# ---------------------------------------------------------------------------
resource "aws_ssm_association" "bastion_patch_scan" {
  name = "AWS-RunPatchBaseline"

  targets {
    key    = "tag:Patch Group"
    values = ["${var.name}-patch-group"]
  }

  parameters = {
    Operation = "Scan"
  }

  schedule_expression = "cron(0 1 ? * SUN *)"

  # Compliance results are visible in AWS Systems Manager > Compliance
  compliance_severity = "HIGH"
}
