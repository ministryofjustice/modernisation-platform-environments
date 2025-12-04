# SSM Maintenance Window (MW) IAM Role & Policy
resource "aws_iam_role" "mw_execution_role" {
  count = local.environment == "development" ? 1 : local.environment == "production" ? 1 : 0
  name  = "ssm-maintenance-window-ami-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["ssm.amazonaws.com", "ec2.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "mw_execution_policy" {
  count       = local.environment == "development" ? 1 : local.environment == "production" ? 1 : 0
  name        = "ssm-maintenance-window-ami-policy"
  description = "Allows SSM MW to run automation and create AMIs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRunningAutomation"
        Effect = "Allow"
        Action = [
          "ssm:StartAutomationExecution",
          "ssm:GetAutomationExecution",
          "ssm:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCreatingImages"
        Effect = "Allow"
        Action = [
          "ec2:CreateImage",
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:CreateTags",
          "ec2:DeleteSnapshot",
          "ec2:DeregisterImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mw_attach" {
  count      = local.environment == "development" ? 1 : local.environment == "production" ? 1 : 0
  role       = aws_iam_role.mw_execution_role[0].name
  policy_arn = aws_iam_policy.mw_execution_policy[0].arn
}

# SSM Maintenance Window
resource "aws_ssm_maintenance_window" "snapshot_window" {
  count                      = local.environment == "development" ? 1 : local.environment == "production" ? 1 : 0
  name                       = "tariff-app-one-time-ami-creation"
  schedule                   = "at(${local.mw_date_time})"
  duration                   = 1
  cutoff                     = 0
  allow_unassociated_targets = true
}

# Target registration
resource "aws_ssm_maintenance_window_target" "target_instance" {
  count         = local.environment == "development" ? 1 : local.environment == "production" ? 1 : 0
  window_id     = aws_ssm_maintenance_window.snapshot_window[0].id
  name          = "target-instance-for-ami"
  description   = "Targeting specific instance ID"
  resource_type = "INSTANCE"
  targets {
    key    = "InstanceIds"
    values = [local.mw_ami_target_id]
  }
}


# Task registration
resource "aws_ssm_maintenance_window_task" "create_image_task" {
  count            = local.environment == "development" ? 1 : local.environment == "production" ? 1 : 0
  window_id        = aws_ssm_maintenance_window.snapshot_window[0].id
  name             = "create-ami-task"
  description      = "Creates an AMI of the target instance"
  task_type        = "AUTOMATION"
  task_arn         = "AWS-CreateImage"
  priority         = 1
  service_role_arn = aws_iam_role.mw_execution_role[0].arn
  max_concurrency  = "1"
  max_errors       = "1"
  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.target_instance[0].id]
  }
  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"
      parameter {
        name   = "InstanceId"
        values = [local.mw_ami_target_id]
      }
      # Optional: NO REBOOT!!
      parameter {
        name   = "NoReboot"
        values = ["true"]
      }
      parameter {
        name   = "Description"
        values = ["Created via Terraform SSM Maintenance Window"]
      }
    }
  }
}