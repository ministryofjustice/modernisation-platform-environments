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
    cloudwatch_metric_alarms_default_actions     = ["dso_pagerduty"]
    enable_application_environment_wildcard_cert = true
    enable_backup_plan_daily_and_weekly          = true
    enable_business_unit_kms_cmks                = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    enable_ec2_user_keypair                      = true
    enable_ec2_oracle_enterprise_managed_server  = true
    enable_shared_s3                             = true # adds permissions to ec2s to interact with devtest or prodpreprod buckets
    enable_observability_platform_monitoring     = lookup(local.baseline_environment_presets_options, "enable_observability_platform_monitoring", false)
    db_backup_s3                                 = true # adds db backup buckets
    iam_policies_ec2_default                     = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies                              = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_filter                          = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy", "Ec2OracleEnterpriseManagerPolicy"]
  }
}

module "baseline" {
  source = "../../modules/baseline"

  providers = {
    aws                       = aws
    aws.core-network-services = aws.core-network-services
    aws.core-vpc              = aws.core-vpc
    aws.us-east-1             = aws.us-east-1
  }

  environment            = module.environment

  # bastion_linux = merge(
  #   local.baseline_bastion_linux,
  #   lookup(local.environment_config, "baseline_bastion_linux", {})
  # )

  acm_certificates = merge(
    module.baseline_presets.acm_certificates,
    lookup(local.environment_config, "baseline_acm_certificates", {})
  )

  # backups = {
  #   "everything" = {
  #     plans = merge(
  #       module.baseline_presets.backup_plans,
  #       local.baseline_backup_plans,
  #       lookup(local.environment_config, "baseline_backup_plans", {})
  #     )
  #   }
  # }
  cloudwatch_metric_alarms = merge(
    local.baseline_cloudwatch_metric_alarms,
    lookup(local.environment_config, "baseline_cloudwatch_metric_alarms", {})
  )
  cloudwatch_log_metric_filters = merge(
    local.baseline_cloudwatch_log_metric_filters,
    lookup(local.environment_config, "baseline_cloudwatch_log_metric_filters", {})
  )
  cloudwatch_log_groups = merge(
    module.baseline_presets.cloudwatch_log_groups,
    local.baseline_cloudwatch_log_groups,
    lookup(local.environment_config, "baseline_cloudwatch_log_groups", {})
  )
  ec2_autoscaling_groups = merge(
    local.baseline_ec2_autoscaling_groups,
    lookup(local.environment_config, "baseline_ec2_autoscaling_groups", {})
  )
  ec2_instances = merge(
    local.baseline_ec2_instances,
    lookup(local.environment_config, "baseline_ec2_instances", {})
  )
  iam_policies = merge(
    module.baseline_presets.iam_policies,
    local.baseline_iam_policies,
    lookup(local.environment_config, "baseline_iam_policies", {})
  )
  iam_roles = merge(
    module.baseline_presets.iam_roles,
    local.baseline_iam_roles,
    lookup(local.environment_config, "baseline_iam_roles", {})
  )
  # iam_service_linked_roles = merge(
  #   module.baseline_presets.iam_service_linked_roles,
  #   local.baseline_iam_service_linked_roles,
  #   lookup(local.environment_config, "baseline_iam_service_linked_roles", {})
  # )
  key_pairs = merge(
    module.baseline_presets.key_pairs,
    local.baseline_key_pairs,
    lookup(local.environment_config, "baseline_key_pairs", {})
  )
  kms_grants = merge(
    module.baseline_presets.kms_grants,
    local.baseline_kms_grants,
    lookup(local.environment_config, "baseline_kms_grants", {})
  )
  lbs = merge(
    local.baseline_lbs,
    lookup(local.environment_config, "baseline_lbs", {})
  )
  resource_explorer      = true
  route53_resolvers = merge(
    module.baseline_presets.route53_resolvers,
    local.baseline_route53_resolvers,
    lookup(local.environment_config, "baseline_route53_resolvers", {})
  )
  route53_zones = merge(
    local.baseline_route53_zones,
    lookup(local.environment_config, "baseline_route53_zones", {})
  )
  s3_buckets = merge(
    module.baseline_presets.s3_buckets,
    local.baseline_s3_buckets,
    lookup(local.environment_config, "baseline_s3_buckets", {})
  )
  secretsmanager_secrets = merge(
    local.baseline_secretsmanager_secrets,
    lookup(local.environment_config, "baseline_secretsmanager_secrets", {})
  )
  security_groups = merge(
    local.baseline_security_groups,
    lookup(local.environment_config, "baseline_security_groups", {})
  )
  sns_topics             = merge(
    module.baseline_presets.sns_topics,
    local.baseline_sns_topics,
    lookup(local.environment_config, "baseline_sns_topics", {})
  )
  ssm_parameters = merge(
    module.baseline_presets.ssm_parameters,
    local.baseline_ssm_parameters,
    lookup(local.environment_config, "baseline_ssm_parameters", {}),
  )
}
