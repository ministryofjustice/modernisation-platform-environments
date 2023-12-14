locals {
  business_unit = var.networking[0].business-unit
  region        = "eu-west-2"

  environment_configs = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }
  baseline_environment_config = local.environment_configs[local.environment]

  baseline_presets_options = {
    enable_application_environment_wildcard_cert = false
    enable_backup_plan_daily_and_weekly          = true
    enable_business_unit_kms_cmks                = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    enable_ec2_oracle_enterprise_manager         = true
    enable_ec2_reduced_ssm_policy                = true
    enable_ec2_user_keypair                      = true
    enable_shared_s3                             = true # adds permissions to ec2s to interact with devtest or prodpreprod buckets
    db_backup_s3                                 = true # adds db backup buckets
    cloudwatch_metric_alarms                     = {}
    route53_resolver_rules = {
      # outbound-data-and-private-subnets = ["azure-fixngo-domain"]  # already set by nomis account
    }
    iam_policies_filter      = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_ec2_default = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies          = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    sns_topics               = {}
  }

  baseline_acm_certificates              = {}
  baseline_backup_plans                  = {}
  baseline_cloudwatch_log_groups         = {}
  baseline_cloudwatch_log_metric_filters = {}
  baseline_cloudwatch_metric_alarms      = {}
  baseline_ec2_autoscaling_groups        = {}
  baseline_ec2_instances                 = {}
  baseline_iam_policies = {
    DbRefresherPolicy = {
      description = "Permissions for the db refresh process"
      statements = [
        {
          sid    = "DescribeInstances"
          effect = "Allow"
          actions = [
            "ec2:DescribeInstances",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "KMSAccess"
          effect = "Allow"
          actions = [
            "kms:GenerateDataKey",
            "kms:Decrypt",
            "kms:Encrypt",
          ]
          resources = [
            data.aws_kms_key.general_shared.arn,
          ]
        },
        {
          sid    = "S3ObjectAccess"
          effect = "Allow"
          actions = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
          ]
          resources = [
            "${module.baseline.s3_buckets["s3-bucket"].bucket.arn}/*",
          ]
        },
        {
          sid    = "SSMParameterAccess"
          effect = "Allow"
          actions = [
            "ssm:GetParameter",
            "ssm:GetParameters",
            "ssm:GetParametersByPath",
          ]
          resources = [
            "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/ansible/*",
          ]
        },
      ]
    }
  }
  baseline_iam_roles = {
    DBRefresherRole = {
      assume_role_policy = [
        {
          effect = "Allow"
          actions = [
            "sts:AssumeRoleWithWebIdentity",
          ]
          principals = {
            type = "Federated"
            identifiers = [
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
            ]

          }
          conditions = [
            {
              test     = "StringEquals"
              values   = ["sts.amazonaws.com"]
              variable = "token.actions.githubusercontent.com:aud"
            },
            {
              test     = "StringLike"
              values   = ["repo:ministryofjustice/dso-modernisation-platform-automation:ref:refs/heads/main"]
              variable = "token.actions.githubusercontent.com:sub"
            }
          ]
        }
      ]
    }
  }
  baseline_iam_service_linked_roles = {}
  baseline_key_pairs                = {}
  baseline_kms_grants               = {}
  baseline_lbs                      = {}
  baseline_route53_resolvers        = {}
  baseline_route53_zones            = {}

  baseline_s3_buckets = {
    s3-bucket = {
      iam_policies = module.baseline_presets.s3_iam_policies
    }
  }

  baseline_secretsmanager_secrets = {}

  baseline_ssm_parameters = {
    "/ansible" = {
      parameters = {
        ssm_bucket = {
          description = "Ansible S3 bucket"
          value       = module.baseline.s3_buckets["s3-bucket"].bucket.bucket
        }
      }
    }
  }

  baseline_security_groups = {
    data-oem = local.security_groups.data_oem
  }

  baseline_sns_topics = {}
}
