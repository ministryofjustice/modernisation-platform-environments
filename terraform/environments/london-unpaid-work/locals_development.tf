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

    secretsmanager_secrets = {
      "/london-unpaid-work-dev/admin"       = local.secretsmanager_secrets.london_unpaid_work_admin_credentials
      "/london-unpaid-work-dev/application" = local.secretsmanager_secrets.london_unpaid_work_application_credentials
      "/london-unpaid-work-dev/rds"         = local.secretsmanager_secrets.london_unpaid_work_rds_credentials
      "/london-unpaid-work-dev/ses"         = local.secretsmanager_secrets.london_unpaid_work_ses_credentials
      "/london-unpaid-work-dev/slack"       = local.secretsmanager_secrets.london_unpaid_work_slack_credentials
      "/london-unpaid-work-dev/test"        = local.secretsmanager_secrets.london_unpaid_work_test_credentials
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
