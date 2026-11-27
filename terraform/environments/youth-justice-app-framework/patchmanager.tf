resource "aws_ssm_patch_baseline" "yjaf_amazon_linux_2" {
  name             = "YJAF-AmazonLinux2PatchBaseline"
  operating_system = "AMAZON_LINUX_2"
  description      = "YJAF Patch Baseline for Amazon Linux 2."

  approval_rule {
    approve_after_days  = 1
    compliance_level    = "CRITICAL"
    enable_non_security = false

    patch_filter {
      key    = "PRODUCT"
      values = ["*"]
    }

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["*"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical"]
    }
  }

  approval_rule {
    approve_after_days  = 1
    compliance_level    = "HIGH"
    enable_non_security = false

    patch_filter {
      key    = "PRODUCT"
      values = ["*"]
    }

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["*"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Important"]
    }
  }

  approval_rule {
    approve_after_days  = 1
    compliance_level    = "INFORMATIONAL"
    enable_non_security = true

    patch_filter {
      key    = "PRODUCT"
      values = ["*"]
    }

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["*"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["*"]
    }
  }

  approved_patches_compliance_level    = "CRITICAL"
  approved_patches_enable_non_security = false
  rejected_patches_action              = "ALLOW_AS_DEPENDENCY"
}

resource "aws_ssm_patch_group" "yjaf_amazon_linux_2_patch_group" {
  baseline_id = aws_ssm_patch_baseline.yjaf_amazon_linux_2.id
  patch_group = "Linux2"
}

resource "aws_ssm_patch_baseline" "yjaf_amazon_linux_2023" {
  name             = "YJAF-AmazonLinux2023PatchBaseline"
  operating_system = "AMAZON_LINUX_2023"
  description      = "YJAF Patch Baseline for Amazon Linux 2023."

  approval_rule {
    approve_after_days  = 1
    compliance_level    = "CRITICAL"
    enable_non_security = false

    patch_filter {
      key    = "PRODUCT"
      values = ["*"]
    }

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["*"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical"]
    }
  }

  approval_rule {
    approve_after_days  = 1
    compliance_level    = "HIGH"
    enable_non_security = false

    patch_filter {
      key    = "PRODUCT"
      values = ["*"]
    }

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["*"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Important"]
    }
  }

  approval_rule {
    approve_after_days  = 1
    compliance_level    = "INFORMATIONAL"
    enable_non_security = true

    patch_filter {
      key    = "PRODUCT"
      values = ["*"]
    }

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["*"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["*"]
    }
  }

  approved_patches_compliance_level    = "CRITICAL"
  approved_patches_enable_non_security = false
  rejected_patches_action              = "ALLOW_AS_DEPENDENCY"
}

resource "aws_ssm_patch_group" "yjaf_amazon_linux_2023_patch_group" {
  baseline_id = aws_ssm_patch_baseline.yjaf_amazon_linux_2023.id
  patch_group = "Linux2023"
}

resource "aws_ssm_patch_baseline" "yjaf_ubuntu_patch_baseline" {
  name             = "YJAF-UbuntuPatchBaseline"
  operating_system = "UBUNTU"
  description      = "YJAF Patch Baseline for Ubuntu"

  approval_rule {
    approve_after_days  = 1
    compliance_level    = "INFORMATIONAL"
    enable_non_security = true

    patch_filter {
      key    = "PRODUCT"
      values = ["*"]
    }

    patch_filter {
      key    = "SECTION"
      values = ["*"]
    }

    patch_filter {
      key    = "PRIORITY"
      values = ["*"]
    }
  }

  approved_patches_compliance_level    = "UNSPECIFIED"
  approved_patches_enable_non_security = false
  rejected_patches_action              = "ALLOW_AS_DEPENDENCY"
}

resource "aws_ssm_patch_group" "yjaf_ubuntu_patch_group" {
  baseline_id = aws_ssm_patch_baseline.yjaf_ubuntu_patch_baseline.id
  patch_group = "Ubuntu"
}

resource "aws_ssm_patch_baseline" "yjaf_windows_patch_baseline" {
  name             = "YJAF-WindowsPatchBaseline"
  operating_system = "WINDOWS"
  description      = "YJAF Patch Baseline for Windows Server"

  approval_rule {
    approve_after_days  = 1
    compliance_level    = "CRITICAL"
    enable_non_security = false

    patch_filter {
      key    = "PATCH_SET"
      values = ["OS"]
    }

    patch_filter {
      key    = "PRODUCT"
      values = ["*"]
    }

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["*"]
    }

    patch_filter {
      key    = "MSRC_SEVERITY"
      values = ["Critical"]
    }
  }

  approval_rule {
    approve_after_days  = 1
    compliance_level    = "HIGH"
    enable_non_security = false

    patch_filter {
      key    = "PATCH_SET"
      values = ["OS"]
    }

    patch_filter {
      key    = "PRODUCT"
      values = ["*"]
    }

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["*"]
    }

    patch_filter {
      key    = "MSRC_SEVERITY"
      values = ["Important"]
    }
  }

  approval_rule {
    approve_after_days  = 7
    compliance_level    = "INFORMATIONAL"
    enable_non_security = false

    patch_filter {
      key    = "PATCH_SET"
      values = ["OS"]
    }

    patch_filter {
      key    = "PRODUCT"
      values = ["*"]
    }

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["*"]
    }

    patch_filter {
      key    = "MSRC_SEVERITY"
      values = ["*"]
    }
  }

  approved_patches_compliance_level    = "CRITICAL"
  approved_patches_enable_non_security = false
  rejected_patches_action              = "ALLOW_AS_DEPENDENCY"
}

resource "aws_ssm_patch_group" "yjaf_windows_patch_group" {
  baseline_id = aws_ssm_patch_baseline.yjaf_windows_patch_baseline.id
  patch_group = "Windows"
}



resource "aws_ssm_association" "patch_schedule" {
  name = "AWS-RunPatchBaseline"

  # Target EC2 instances with the Patch Group tag
  targets {
    key    = "tag:Patch Group"
    values = ["Linux2", "Linux2023", "Ubuntu", "Windows"]
  }

  # Production: Sunday 03:00 UTC. Non-production instances are shut down overnight and at weekends,
  # so patch on Monday morning once the instances have started
  schedule_expression = local.is-production ? "cron(0 3 ? * SUN *)" : "cron(0 8 ? * MON *)"

  # Without this, every update to the association (e.g. a schedule or target change) triggers an immediate patch run
  apply_only_at_cron_interval = true

  compliance_severity = "HIGH"
  max_concurrency     = "50%"
  max_errors          = "1"

  automation_target_parameter_name = "InstanceId"
  parameters = {
    Operation = "Install"
  }
}