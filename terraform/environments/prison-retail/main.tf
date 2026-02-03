# Majority of resources created by baseline module.
# See common settings in locals.tf and environment specific settings in
# locals_development.tf, locals_test.tf etc.

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
  business_unit          = var.networking[0].business-unit
  application_name       = local.application_name
  environment            = local.environment
  subnet_set             = local.subnet_set
}

module "baseline_presets" {
  source = "../../modules/baseline_presets"

  environment  = module.environment
  ip_addresses = module.ip_addresses

  options = merge(
    local.baseline_presets_all_environments.options,
    local.baseline_presets_environment_specific.options
  )
}

module "baseline" {
  source = "../../modules/baseline"

  providers = {
    aws                       = aws
    aws.core-network-services = aws.core-network-services
    aws.core-vpc              = aws.core-vpc
    aws.us-east-1             = aws.us-east-1
  }

  environment = module.environment

  acm_certificates = merge(
    module.baseline_presets.acm_certificates,
    lookup(local.baseline_all_environments, "acm_certificates", {}),
    lookup(local.baseline_environment_specific, "acm_certificates", {}),
  )

  backups = {
    "everything" = {
      plans = merge(
        module.baseline_presets.backup_plans,
        lookup(local.baseline_all_environments, "backup_plans", {}),
        lookup(local.baseline_environment_specific, "backup_plans", {}),
      )
    }
  }

  bastion_linux = merge(
    lookup(local.baseline_all_environments, "bastion_linux", {}),
    lookup(local.baseline_environment_specific, "bastion_linux", {}),
  )

  cloudwatch_dashboards = merge(
    module.baseline_presets.cloudwatch_dashboards,
    lookup(local.baseline_all_environments, "cloudwatch_dashboards", {}),
    lookup(local.baseline_environment_specific, "cloudwatch_dashboards", {}),
  )

  cloudwatch_event_rules = merge(
    module.baseline_presets.cloudwatch_event_rules,
    lookup(local.baseline_all_environments, "cloudwatch_event_rules", {}),
    lookup(local.baseline_environment_specific, "cloudwatch_event_rules", {}),
  )

  cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms_baseline,
    lookup(local.baseline_all_environments, "cloudwatch_metric_alarms", {}),
    lookup(local.baseline_environment_specific, "cloudwatch_metric_alarms", {}),
  )

  cloudwatch_log_metric_filters = merge(
    lookup(local.baseline_all_environments, "cloudwatch_log_metric_filters", {}),
    lookup(local.baseline_environment_specific, "cloudwatch_log_metric_filters", {}),
  )

  cloudwatch_log_groups = merge(
    module.baseline_presets.cloudwatch_log_groups,
    lookup(local.baseline_all_environments, "cloudwatch_log_groups", {}),
    lookup(local.baseline_environment_specific, "cloudwatch_log_groups", {}),
  )

  data_firehoses = merge(
    module.baseline_presets.data_firehoses,
    lookup(local.baseline_all_environments, "data_firehoses", {}),
    lookup(local.baseline_environment_specific, "data_firehoses", {}),
  )

  ec2_autoscaling_groups = merge(
    lookup(local.baseline_all_environments, "ec2_autoscaling_groups", {}),
    lookup(local.baseline_environment_specific, "ec2_autoscaling_groups", {}),
  )

  ec2_instances = merge(
    lookup(local.baseline_all_environments, "ec2_instances", {}),
    lookup(local.baseline_environment_specific, "ec2_instances", {}),
  )

  efs = merge(
    lookup(local.baseline_all_environments, "efs", {}),
    lookup(local.baseline_environment_specific, "efs", {}),
  )

  fsx_windows = merge(
    lookup(local.baseline_all_environments, "fsx_windows", {}),
    lookup(local.baseline_environment_specific, "fsx_windows", {}),
  )

  iam_policies = merge(
    module.baseline_presets.iam_policies,
    lookup(local.baseline_all_environments, "iam_policies", {}),
    lookup(local.baseline_environment_specific, "iam_policies", {}),
  )

  iam_roles = merge(
    module.baseline_presets.iam_roles,
    lookup(local.baseline_all_environments, "iam_roles", {}),
    lookup(local.baseline_environment_specific, "iam_roles", {}),
  )

  iam_service_linked_roles = merge(
    module.baseline_presets.iam_service_linked_roles,
    lookup(local.baseline_all_environments, "iam_service_linked_roles", {}),
    lookup(local.baseline_environment_specific, "iam_service_linked_roles", {}),
  )

  key_pairs = merge(
    module.baseline_presets.key_pairs,
    lookup(local.baseline_all_environments, "key_pairs", {}),
    lookup(local.baseline_environment_specific, "key_pairs", {}),
  )

  kms_grants = merge(
    module.baseline_presets.kms_grants,
    lookup(local.baseline_all_environments, "kms_grants", {}),
    lookup(local.baseline_environment_specific, "kms_grants", {}),
  )

  lbs = merge(
    lookup(local.baseline_all_environments, "lbs", {}),
    lookup(local.baseline_environment_specific, "lbs", {}),
  )

  oam_links = merge(
    module.baseline_presets.oam_links,
    lookup(local.baseline_all_environments, "oam_links", {}),
    lookup(local.baseline_environment_specific, "oam_links", {}),
  )

  oam_sinks = merge(
    lookup(local.baseline_all_environments, "oam_sinks", {}),
    lookup(local.baseline_environment_specific, "oam_sinks", {}),
  )

  options = merge(
    lookup(local.baseline_all_environments, "options", {}),
    lookup(local.baseline_environment_specific, "options", {}),
  )

  route53_resolvers = merge(
    module.baseline_presets.route53_resolvers,
    lookup(local.baseline_all_environments, "route53_resolvers", {}),
    lookup(local.baseline_environment_specific, "route53_resolvers", {}),
  )

  route53_zones = merge(
    lookup(local.baseline_all_environments, "route53_zones", {}),
    lookup(local.baseline_environment_specific, "route53_zones", {}),
  )

  s3_buckets = merge(
    module.baseline_presets.s3_buckets,
    lookup(local.baseline_all_environments, "s3_buckets", {}),
    lookup(local.baseline_environment_specific, "s3_buckets", {}),
  )

  schedule_alarms_lambda = merge(
    lookup(local.baseline_all_environments, "schedule_alarms_lambda", {}),
    lookup(local.baseline_environment_specific, "schedule_alarms_lambda", {}),
  )

  secretsmanager_secrets = merge(
    module.baseline_presets.secretsmanager_secrets,
    lookup(local.baseline_all_environments, "secretsmanager_secrets", {}),
    lookup(local.baseline_environment_specific, "secretsmanager_secrets", {}),
  )

  security_groups = merge(
    module.baseline_presets.security_groups,
    lookup(local.baseline_all_environments, "security_groups", {}),
    lookup(local.baseline_environment_specific, "security_groups", {}),
  )

  sns_topics = merge(
    module.baseline_presets.sns_topics,
    lookup(local.baseline_all_environments, "sns_topics", {}),
    lookup(local.baseline_environment_specific, "sns_topics", {}),
  )

  sqs_queues = merge(
    module.baseline_presets.sqs_queues,
    lookup(local.baseline_all_environments, "sqs_queues", {}),
    lookup(local.baseline_environment_specific, "sqs_queues", {}),
  )

  ssm_associations = merge(
    module.baseline_presets.ssm_associations,
    lookup(local.baseline_all_environments, "ssm_associations", {}),
    lookup(local.baseline_environment_specific, "ssm_associations", {}),
  )

  ssm_documents = merge(
    module.baseline_presets.ssm_documents,
    lookup(local.baseline_all_environments, "ssm_documents", {}),
    lookup(local.baseline_environment_specific, "ssm_documents", {}),
  )

  ssm_parameters = merge(
    module.baseline_presets.ssm_parameters,
    lookup(local.baseline_all_environments, "ssm_parameters", {}),
    lookup(local.baseline_environment_specific, "ssm_parameters", {}),
  )
}
