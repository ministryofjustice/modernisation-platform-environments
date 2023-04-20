module "baseline" {
  source = "../../modules/baseline"

  providers = {
    aws                       = aws
    aws.core-network-services = aws.core-network-services
    aws.core-vpc              = aws.core-vpc
  }

  environment = module.environment

  acm_certificates = merge(
    module.baseline_presets.acm_certificates,
    local.baseline_acm_certificates,
    lookup(local.baseline_environment_config, "baseline_acm_certificates", {})
  )

  cloudwatch_log_groups = merge(
    module.baseline_presets.cloudwatch_log_groups,
    local.baseline_cloudwatch_log_groups,
    lookup(local.baseline_environment_config, "baseline_cloudwatch_log_groups", {})
  )

  ec2_autoscaling_groups = merge(
    local.baseline_ec2_autoscaling_groups,
    lookup(local.baseline_environment_config, "baseline_ec2_autoscaling_groups", {})
  )

  ec2_instances = merge(
    local.baseline_ec2_instances,
    lookup(local.baseline_environment_config, "baseline_ec2_instances", {})
  )

  iam_policies = merge(
    module.baseline_presets.iam_policies,
    local.baseline_iam_policies,
    lookup(local.baseline_environment_config, "baseline_iam_policies", {})
  )

  iam_roles = merge(
    module.baseline_presets.iam_roles,
    local.baseline_iam_roles,
    lookup(local.baseline_environment_config, "baseline_iam_roles", {})
  )

  # iam_service_linked_roles = merge(
  #   module.baseline_presets.iam_service_linked_roles,
  #   local.baseline_iam_service_linked_roles,
  #   lookup(local.baseline_environment_config, "baseline_iam_service_linked_roles", {})
  # )

  # key_pairs = merge(
  #   module.baseline_presets.key_pairs,
  #   local.baseline_key_pairs,
  #   lookup(local.baseline_environment_config, "baseline_key_pairs", {})
  # )

  kms_grants = merge(
    module.baseline_presets.kms_grants,
    local.baseline_kms_grants,
    lookup(local.baseline_environment_config, "baseline_kms_grants", {})
  )

  lbs = merge(
    local.baseline_lbs,
    lookup(local.baseline_environment_config, "baseline_lbs", {})
  )

  route53_resolvers = merge(
    module.baseline_presets.route53_resolvers,
    local.baseline_route53_resolvers,
    lookup(local.baseline_environment_config, "baseline_route53_resolvers", {})
  )

  route53_zones = merge(
    local.baseline_route53_zones,
    lookup(local.baseline_environment_config, "baseline_route53_zones", {})
  )

  # s3_buckets = merge(
  #   module.baseline_presets.s3_buckets,
  #   local.baseline_s3_buckets,
  #   lookup(local.baseline_environment_config, "baseline_s3_buckets", {})
  # )
  #

  security_groups = merge(
    local.baseline_security_groups,
    lookup(local.baseline_environment_config, "baseline_security_groups", {})
  )

  sns_topics = merge(
    module.baseline_presets.sns_topics,
    local.baseline_sns_topics,
    lookup(local.baseline_environment_config, "baseline_sns_topics", {})
  )

}
