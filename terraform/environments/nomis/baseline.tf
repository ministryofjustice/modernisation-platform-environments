module "baseline" {
  source = "../../modules/baseline"

  providers = {
    aws                       = aws
    aws.core-network-services = aws.core-network-services
    aws.core-vpc              = aws.core-vpc
  }

  environment = module.environment

  # security_groups          = local.baseline_security_groups
  acm_certificates = module.baseline_presets.acm_certificates
  # cloudwatch_log_groups    = module.baseline_presets.cloudwatch_log_groups
  # iam_policies             = module.baseline_presets.iam_policies
  # iam_roles                = module.baseline_presets.iam_roles
  # iam_service_linked_roles = module.baseline_presets.iam_service_linked_roles
  # key_pairs                = module.baseline_presets.key_pairs
  # kms_grants               = module.baseline_presets.kms_grants
  # s3_buckets               = merge(local.baseline_s3_buckets, lookup(local.baseline_environment_config, "baseline_s3_buckets", {}))
  # ec2_instances          = lookup(local.baseline_environment_config, "baseline_ec2_instances", {})
  # ec2_autoscaling_groups = lookup(local.baseline_environment_config, "baseline_ec2_autoscaling_groups", {})
  route53_resolvers = module.baseline_presets.route53_resolvers
  lbs               = lookup(local.baseline_environment_config, "baseline_lbs", {})
}
