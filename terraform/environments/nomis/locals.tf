locals {
  business_unit = var.networking[0].business-unit
  region        = "eu-west-2"

  environment_baseline_presets_options = {
    development   = local.development_baseline_presets_options
    test          = local.test_baseline_presets_options
    preproduction = local.preproduction_baseline_presets_options
    production    = local.production_baseline_presets_options
  }
  environment_configs = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }
  baseline_environment_presets_options = local.environment_baseline_presets_options[local.environment]
  baseline_environment_config          = local.environment_configs[local.environment]

  baseline_presets_options = {
    enable_application_environment_wildcard_cert = false
    enable_backup_plan_daily_and_weekly          = true
    enable_business_unit_kms_cmks                = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_reduced_ssm_policy                = true
    enable_ec2_self_provision                    = true
    enable_ec2_oracle_enterprise_managed_server  = true
    enable_ec2_user_keypair                      = true
    cloudwatch_metric_alarms_default_actions     = ["dso_pagerduty"]
    route53_resolver_rules = {
      outbound-data-and-private-subnets = ["azure-fixngo-domain"]
    }
    iam_policies_filter      = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_ec2_default = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies          = ["EC2S3BucketWriteAndDeleteAccessPolicy"]

    # sns_topics are defined in locals_${environment}.tf
  }

  baseline_acm_certificates = {}

  baseline_backup_plans = {}

  baseline_bastion_linux = {
    public_key_data = merge(
      jsondecode(file(".ssh/user-keys.json"))["all-environments"],
      jsondecode(file(".ssh/user-keys.json"))[local.environment]
    )
    allow_ssh_commands = false
    extra_user_data_content = templatefile("templates/bastion-user-data.sh.tftpl", {
      region                                  = local.region
      application_environment_internal_domain = module.environment.domains.internal.application_environment
      X11Forwarding                           = "no"
    })
  }

  baseline_cloudwatch_log_groups = merge(
    local.weblogic_cloudwatch_log_groups,
    local.database_cloudwatch_log_groups,
  )

  baseline_cloudwatch_metric_alarms      = {}
  baseline_cloudwatch_log_metric_filters = {}

  baseline_ec2_autoscaling_groups = {}
  baseline_ec2_instances          = {}
  baseline_iam_policies = {
    DBRefresherPolicy = {
      description = "Permissions for the db refresh process"
      statements = [
        {
          sid    = "InstanceAccess"
          effect = "Allow"
          actions = [
            "ec2:DescribeInstances",
            "ssm:StartSession",
            "ssm:TerminateSession"
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
    },
    SasTokenRotatorPolicy = {
      description = "Allows updating of secrets in SSM"
      statements = [
        {
          sid    = "RotateSecrets"
          effect = "Allow"
          actions = [
            "ssm:PutParameter",
          ]
          resources = [
            "arn:aws:ssm:*:*:parameter/azure/*",
          ]
        },
        {
          sid    = "EncryptSecrets"
          effect = "Allow"
          actions = [
            "kms:Encrypt",
          ]
          resources = [
            data.aws_kms_key.general_shared.arn,
          ]
        },
      ]
    }
  }
  baseline_iam_roles = {
    DBRefresherRole = {
      description = "Allows the db refresh process to access the database instance"
      assume_role_policy = [{
        effect  = "Allow"
        actions = ["sts:AssumeRoleWithWebIdentity"]
        principals = {
          type        = "Federated"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
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
          },
        ]
        }
      ]
      policy_attachments = [
        "DBRefresherPolicy",
      ]
    },
    SasTokenRotatorRole = {
      assume_role_policy = [{
        effect  = "Allow"
        actions = ["sts:AssumeRoleWithWebIdentity"]
        principals = {
          type        = "Federated"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
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
          },
        ]
      }]
      policy_attachments = [
        "SasTokenRotatorPolicy",
      ]
    }
  }
  baseline_iam_service_linked_roles = {}
  baseline_key_pairs                = {}
  baseline_kms_grants               = {}
  baseline_lbs                      = {}
  baseline_route53_resolvers        = {}

  baseline_route53_zones = {
    "${local.environment}.nomis.az.justice.gov.uk"      = {}
    "${local.environment}.nomis.service.justice.gov.uk" = {}
  }

  baseline_s3_buckets = {
    s3-bucket = {
      iam_policies = module.baseline_presets.s3_iam_policies
    }
  }

  baseline_secretsmanager_secrets = {}

  baseline_security_groups = {
    private-lb         = local.security_groups.private_lb
    private-web        = local.security_groups.private_web
    private-jumpserver = local.security_groups.private_jumpserver
    data-db            = local.security_groups.data_db
  }

  baseline_sns_topics = {}

  baseline_ssm_parameters = {
    "/azure" = {
      parameters = {
        sas_token = { description = "database backup storage account read-only sas token" }
      }
    }
  }
}
