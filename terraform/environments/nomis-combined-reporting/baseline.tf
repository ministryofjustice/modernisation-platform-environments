module "baseline" {
  # source = "../../modules/baseline"
  source = "git::https://github.com/ministryofjustice/modernisation-platform-environments//terraform/modules/baseline?ref=nomis/DSOS-1759/baseline-module"

  providers = {
    aws                       = aws
    aws.core-network-services = aws.core-network-services
    aws.core-vpc              = aws.core-vpc
  }

  environment = module.environment

  security_groups = local.baseline_security_groups
  #acm_certificates      = module.baseline_presets.acm_certificates
  cloudwatch_log_groups    = module.baseline_presets.cloudwatch_log_groups
  iam_policies             = module.baseline_presets.iam_policies
  iam_roles                = module.baseline_presets.iam_roles
  iam_service_linked_roles = module.baseline_presets.iam_service_linked_roles
  key_pairs                = module.baseline_presets.key_pairs
  kms_grants               = module.baseline_presets.kms_grants
  s3_buckets               = merge(local.baseline_s3_buckets, lookup(local.environment_config, "baseline_s3_buckets", {}))

  ec2_instances          = lookup(local.environment_config, "baseline_ec2_instances", {})
  #ec2_autoscaling_groups = lookup(local.environment_config, "baseline_ec2_autoscaling_groups", {})
  #lbs                    = lookup(local.environment_config, "baseline_lbs", {})
}
