locals {
  baseline_presets_development = {
    options = {
      enable_ec2_session_manager_cloudwatch_logs = true
    }
  }

  baseline_development = {
    lbs = {
      api-alb = local.lbs.api-alb,
      web-alb = local.lbs.web-alb
    }

    s3_buckets = {
      artifacts-bucket = {
        tags = {
          backup = "false"
        }
      }
    }

    secretsmanager_secrets = {
      "/london-unpaid-work-dev"             = local.secretsmanager_secrets.london_unpaid_work_dev_secrets
    }

    security_groups = local.security_groups
  }

  security_group_cidrs_development = {
    bastion = flatten([
      "10.161.98.0/28",
      "10.161.98.16/28",
      "10.161.98.32/28"
    ])
  }
}
