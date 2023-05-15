module "ip_addresses" {
  source = "../../modules/ip_addresses"
}

module "environment" {
  source = "../../modules/environment"

  providers = {
    aws.modernisation-platform = aws.modernisation-platform
    aws.core-network-services  = aws.core-network-services
    aws.core-vpc               = aws.core-vpc
  }
  environment_management = local.environment_management
  business_unit          = local.business_unit
  application_name       = local.application_name
  environment            = local.environment
  subnet_set             = local.subnet_set
}

module "baseline_presets" {
  source = "../../modules/baseline_presets"

  environment  = module.environment
  ip_addresses = module.ip_addresses

  options = {
    cloudwatch_log_groups                        = null
    enable_application_environment_wildcard_cert = true
    enable_business_unit_kms_cmks                = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    enable_shared_s3                             = true # adds permissions to ec2s to interact with devtest or prodpreprod buckets
    iam_policies_ec2_default                     = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies                              = ["EC2S3BucketWriteAndDeleteAccessPolicy"]

    cloudwatch_metric_alarms_lists_with_actions = {
      dso_pagerduty = ["dso_pagerduty"]
    }

    sns_topics = {
      pagerduty_integrations = {
        dso_pagerduty = contains(["development", "test"], local.environment) ? "oasys_nonprod_alarms" : "oasys_alarms"
      }
    }

    # comment this in if you need to resolve FixNGo hostnames
    # route53_resolver_rules = {
    #   outbound-data-and-private-subnets = ["azure-fixngo-domain"]
    # }
  }
}

module "baseline" {
  source = "../../modules/baseline"

  providers = {
    aws                       = aws
    aws.core-network-services = aws.core-network-services
    aws.core-vpc              = aws.core-vpc
  }

  # bastion_linux = lookup(local.environment_config, "baseline_bastion_linux", null)
  # iam_service_linked_roles = module.baseline_presets.iam_service_linked_roles
  # rds_instances
  sns_topics             = module.baseline_presets.sns_topics
  #acm_certificates       = merge(module.baseline_presets.acm_certificates, lookup(local.environment_config, "baseline_acm_certificates", {}))
  acm_certificates       = module.baseline_presets.acm_certificates
  cloudwatch_log_groups  = module.baseline_presets.cloudwatch_log_groups
  ec2_autoscaling_groups = lookup(local.environment_config, "baseline_ec2_autoscaling_groups", {})
  ec2_instances          = lookup(local.environment_config, "baseline_ec2_instances", {})
  environment            = module.environment
  iam_policies           = module.baseline_presets.iam_policies
  iam_roles              = module.baseline_presets.iam_roles
  key_pairs              = module.baseline_presets.key_pairs
  kms_grants             = module.baseline_presets.kms_grants
  lbs                    = lookup(local.environment_config, "baseline_lbs", {})
  resource_explorer      = true
  route53_resolvers      = module.baseline_presets.route53_resolvers
  route53_zones          = lookup(local.environment_config, "baseline_route53_zones", {})
  s3_buckets             = merge(local.baseline_s3_buckets, module.baseline_presets.s3_buckets, lookup(local.environment_config, "baseline_s3_buckets", {}))
  security_groups        = local.baseline_security_groups
}
