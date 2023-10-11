output "acm_certificates" {
  description = "Map of acm_certificates to create depending on options provided"

  value = {
    for key, value in local.acm_certificates : key => value if contains(local.acm_certificates_filter, key)
  }
}

output "backup_plans" {
  description = "Map of backup_plans to create depending on options provided"

  value = {
    for key, value in local.backup_plans : key => value if contains(local.backup_plans_filter, key)
  }
}

output "cloudwatch_log_groups" {
  description = "Map of log groups"

  value = var.options.cloudwatch_log_groups != null ? {
    for key, value in local.cloudwatch_log_groups : key => value if contains(var.options.cloudwatch_log_groups, key)
  } : local.cloudwatch_log_groups
}

output "cloudwatch_metric_alarms" {
  description = "Map of common cloudwatch metric alarms grouped by namespace with default action specified by var.options.cloudwatch_metric_alarms_default_actions.  See cloudwatch_metric_alarms.tf for more detail"
  value       = local.cloudwatch_metric_alarms
}

output "ec2_autoscaling_group" {
  description = "Common EC2 autoscaling group configuration for ec2_autoscaling_group module"

  value = local.ec2_autoscaling_group
}

output "ec2_autoscaling_schedules" {
  description = "Common EC2 autoscaling schedules configuration for ec2_autoscaling_group module"

  value = local.ec2_autoscaling_schedules
}

output "ec2_instance" {
  description = "Common EC2 instance configuration for ec2_instance module"

  value = local.ec2_instance
}

output "iam_roles" {
  description = "Map of iam roles to create depending on options provided"

  value = {
    for key, value in local.iam_roles : key => value if contains(local.iam_roles_filter, key)
  }
}

output "iam_service_linked_roles" {
  description = "Map of common service linked roles to create"

  value = local.iam_service_linked_roles
}

output "iam_policies" {
  description = "Map of iam policies to create depending on options provided"

  value = {
    for key, value in local.iam_policies : key => value if contains(local.iam_policies_filter, key)
  }
}

output "key_pairs" {
  description = "Common key pairs to create"

  value = {
    for key, value in local.key_pairs : key => value if contains(local.key_pairs_filter, key)
  }
}

output "kms_grants" {
  description = "Map of kms grants to create depending on options provided"

  value = {
    for key, value in local.kms_grants : key => value if contains(local.kms_grants_filter, key)
  }
}

output "route53_resolver_rules" {
  description = "Map of route53 resolver rules depending on options provided"
  value       = local.route53_resolver_rules
}

output "route53_resolvers" {
  description = "Map of route53 resolvers to create depending on options provided"
  value       = local.route53_resolvers
}

output "s3_bucket_policies" {
  description = "Map of common bucket policies to use on s3_buckets"

  value = local.s3_bucket_policies
}

output "s3_iam_policies" {
  description = "Map of common iam_policies that can be used to give access to s3_buckets"

  value = var.options.s3_iam_policies != null ? {
    for key, value in local.s3_iam_policies : key => value if contains(var.options.s3_iam_policies, key)
  } : local.s3_iam_policies
}

output "s3_buckets" {
  description = "Map of s3_buckets"
  value       = local.s3_buckets
}

output "s3_lifecycle_rules" {
  description = "Map of s3 lifecycle rules that can be used for buckets"
  value       = local.s3_lifecycle_rules
}

output "ssm_parameters" {
  description = "Map of common ssm parameters to create"
  value = {
    for key, value in local.ssm_parameters : key => value if contains(local.ssm_parameters_filter, key)
  }
}

output "sns_topics" {
  description = "Map of sns_topics to create depending on options provided"
  value       = local.sns_topics
}
