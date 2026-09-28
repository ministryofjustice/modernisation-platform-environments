locals {
  baseline_presets_development = {
    options = {
      enable_ec2_session_manager_cloudwatch_logs = true
    }
  }

  baseline_development = {
    ec2_instances = local.ec2_instances

    ec2_autoscaling_groups = local.ec2_autoscaling_groups

    lbs = {
      api-alb = local.lbs.api-alb,
      web-alb = local.lbs.web-alb
    }

    s3_buckets = {
      artifacts-bucket = {
        iam_policies   = module.baseline_presets.s3_iam_policies
        lifecycle_rule = [module.baseline_presets.s3_lifecycle_rules.default]
        tags = {
          backup = "false"
        }
      }
    }

    secretsmanager_secrets = {
      "/london-unpaid-work-dev" = local.secretsmanager_secrets.london_unpaid_work_dev_secrets
    }

    security_groups = local.security_groups

    iam_policies = {
    LondonUnpaidWorkRDSAccessPolicy = {
      description = "Allow database tools server to discover RDS and read its managed credentials"

      statements = [
        {
          sid    = "DescribeDatabase"
          effect = "Allow"
          actions = [
            "rds:DescribeDBInstances",
          ]
          resources = [
            "arn:aws:rds:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:db:${local.account_config.db_identifier}",
          ]
        },
        {
          sid    = "ReadRDSManagedCredentials"
          effect = "Allow"
          actions = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
          ]
          resources = [
            "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:rds!db-*",
          ]
        }
      ]
    }
  }
  }

  security_group_cidrs_development = {
    bastion = flatten([
      "10.161.98.0/28",
      "10.161.98.16/28",
      "10.161.98.32/28"
    ])
  }
}
