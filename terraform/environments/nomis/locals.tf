locals {
  business_unit       = var.networking[0].business-unit
  region              = "eu-west-2"
  availability_zone_1 = "eu-west-2a"
  availability_zone_2 = "eu-west-2b"

  environment_configs = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }
  baseline_environment_config = local.environment_configs[local.environment]

  baseline_presets_options = {
    enable_application_environment_wildcard_cert = false
    enable_business_unit_kms_cmks                = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    cloudwatch_metric_alarms = {
      weblogic = local.weblogic_cloudwatch_metric_alarms
      database = local.database_cloudwatch_metric_alarms
    }
    cloudwatch_metric_alarms_lists = merge(
      local.weblogic_cloudwatch_metric_alarms_lists,
      local.database_cloudwatch_metric_alarms_lists
    )
    cloudwatch_metric_alarms_lists_with_actions = {
      nomis_pagerduty = ["nomis_pagerduty"]
    }
    route53_resolver_rules = {
      outbound-data-and-private-subnets = ["azure-fixngo-domain"]
    }
    iam_policies_filter      = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_ec2_default = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies          = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    sns_topics = {
      pagerduty_integrations = {
        nomis_pagerduty = contains(["development", "test"], local.environment) ? "nomis_nonprod_alarms" : "nomis_alarms"
      }
    }
  }

  baseline_acm_certificates = {}

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
    ec2-image-builder-nomis = {
      custom_kms_key = module.environment.kms_keys["general"].arn
      bucket_policy_v2 = [
        module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
        module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
      ]
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

  baseline_sns_topics = {
    "dba_slack_pagerduty" = {
      display_name      = "Pager duty integration for dba_slack"
      kms_master_key_id = "general"
    }
    "dba_callout_pagerduty" = {
      display_name      = "Pager duty integration for dba_callout"
      kms_master_key_id = "general"
    }
  }

  autoscaling_schedules_default = {
    "scale_up" = {
      recurrence = "0 7 * * Mon-Fri"
    }
    "scale_down" = {
      desired_capacity = 0
      recurrence       = "0 19 * * Mon-Fri"
    }
  }
}

