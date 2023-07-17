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
    enable_oracle_secure_web                     = true
    enable_ec2_put_parameter                     = false
    cloudwatch_metric_alarms = {
      weblogic = local.weblogic_cloudwatch_metric_alarms
      database = local.database_cloudwatch_metric_alarms
    }
    cloudwatch_metric_alarms_lists = merge(
      local.weblogic_cloudwatch_metric_alarms_lists,
      local.database_cloudwatch_metric_alarms_lists
    )
    cloudwatch_metric_alarms_lists_with_actions = {
      dso_pagerduty               = ["dso_pagerduty"]
      dba_pagerduty               = ["dba_pagerduty"]
      dba_high_priority_pagerduty = ["dba_high_priority_pagerduty"]
    }
    route53_resolver_rules = {
      outbound-data-and-private-subnets = ["azure-fixngo-domain"]
    }
    iam_policies_filter      = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_ec2_default = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies          = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    sns_topics = {
      pagerduty_integrations = {
        dso_pagerduty               = contains(["development", "test"], local.environment) ? "nomis_nonprod_alarms" : "nomis_alarms"
        dba_pagerduty               = contains(["development", "test"], local.environment) ? "hmpps_shef_dba_non_prod" : "hmpps_shef_dba_low_priority"
        dba_high_priority_pagerduty = contains(["development", "test"], local.environment) ? "hmpps_shef_dba_non_prod" : "hmpps_shef_dba_high_priority"
      }
    }
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

  baseline_ec2_autoscaling_groups   = {}
  baseline_ec2_instances            = {}
  baseline_iam_policies             = {}
  baseline_iam_roles                = {}
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
    nomis-db-backup-bucket = {
      custom_kms_key = module.environment.kms_keys["general"].arn
      iam_policies   = module.baseline_presets.s3_iam_policies
    }
    nomis-audit-archives = {
      custom_kms_key = module.environment.kms_keys["general"].arn
      bucket_policy_v2 = [
        module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
      ]
      iam_policies = module.baseline_presets.s3_iam_policies
    }
  }

  baseline_security_groups = {
    private-lb         = local.security_groups.private_lb
    private-web        = local.security_groups.private_web
    private-jumpserver = local.security_groups.private_jumpserver
    data-db            = local.security_groups.data_db
  }

  baseline_sns_topics = {}

  baseline_ssm_parameters = {
    "" = {
      postfix = ""
      parameters = {
        cloud-watch-config-windows = {
          description = "cloud watch agent config for windows"
          file        = "./templates/cloud_watch_windows.json"
          type        = "String"
        }

        # Placeholders - set values outside of terraform
        ec2-user_pem       = { description = "ec2-user ssh private key" }
        github-ci-user-pat = { description = "for SSM docs, see ssm-documents/README.md" }
      }
    }
  }
}
