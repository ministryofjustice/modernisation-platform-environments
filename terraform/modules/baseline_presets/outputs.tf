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

output "cloudwatch_dashboard_widgets" {
  description = "Map of common cloudwatch dashboard widgets grouped by namespace"
  value       = local.cloudwatch_dashboard_widgets
}

output "cloudwatch_dashboard_widget_groups" {
  description = "Map of common cloudwatch dashboard widget groups"
  value       = local.cloudwatch_dashboard_widget_groups
}

output "cloudwatch_dashboards" {
  description = "Map of common cloudwatch dashboards"
  value = {
    for key, value in local.cloudwatch_dashboards : key => value if contains(local.cloudwatch_dashboards_filter, key)
  }
}

output "cloudwatch_event_rules" {
  description = "Map of common cloudwatch_event_rules to create"
  value       = local.cloudwatch_event_rules
}

output "cloudwatch_log_groups" {
  description = "Map of log groups"

  value = {
    for key, value in local.cloudwatch_log_groups : key => value if contains(local.cloudwatch_log_groups_filter, key)
  }
}

output "cloudwatch_metric_alarms" {
  description = "Map of common cloudwatch metric alarms grouped by namespace with default action specified by var.options.cloudwatch_metric_alarms_default_actions.  See cloudwatch_metric_alarms.tf for more detail"
  value       = local.cloudwatch_metric_alarms
}

output "cloudwatch_metric_alarms_baseline" {
  description = "Map of common cloudwatch metric alarms that can be passed into baseline directly as specified by var.options.enable_ssm_command_monitoring for example"
  value       = local.cloudwatch_metric_alarms_baseline
}

output "cloudwatch_metric_alarms_by_sns_topic" {
  description = "Map of sns topic key to cloudwatch metric alarms grouped by namespace, where the default action is the sns topic key"

  value = local.cloudwatch_metric_alarms_by_sns_topic
}

output "data_firehoses" {
  description = "Map of data firehoses"

  value = {
    for key, value in local.data_firehoses : key => value if contains(local.data_firehoses_filter, key)
  }
}

output "iam_roles" {
  description = "Map of iam roles to create depending on options provided"

  value = {
    for key, value in local.iam_roles : key => value if contains(local.iam_roles_filter, key)
  }
}

output "iam_service_linked_roles" {
  description = "Map of common service linked roles to create"

  value = var.options.iam_service_linked_roles != null ? {
    for key, value in local.iam_service_linked_roles : key => value if contains(var.options.iam_service_linked_roles, key)
  } : local.iam_service_linked_roles
}

output "iam_policies" {
  description = "Map of iam policies to create depending on options provided"

  value = {
    for key, value in local.iam_policies : key => value if contains(local.iam_policies_filter, key)
  }
}

output "iam_policy_statements_ec2" {
  description = "Map of iam policy statements for ec2 instances"

  value = local.iam_policy_statements_ec2
}

output "iam_policy_statements_s3" {
  description = "Map of iam policy statements for s3 buckets"

  value = local.iam_policy_statements_s3
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

output "oam_links" {
  description = "Map of oam_links to create depending on options provided"
  value       = local.oam_links
}

output "route53_resolver_rules" {
  description = "Map of route53 resolver rules depending on options provided"
  value       = local.route53_resolver_rules
}

output "route53_resolvers" {
  description = "Map of route53 resolvers to create depending on options provided"
  value       = local.route53_resolvers
}

output "s3_buckets" {
  description = "Map of requested s3_buckets"
  value = {
    for key, value in local.s3_buckets : key => value if contains(local.s3_buckets_filter, key)
  }
}

output "s3_bucket_policies" {
  description = "Map of common bucket policies to use on s3_buckets"

  value = local.s3_bucket_policies
}

output "s3_iam_policies" {
  description = "Map of common iam_policies that can be used to give access to s3_buckets"

  value = local.requested_s3_iam_policies
}

output "s3_lifecycle_rules" {
  description = "Map of s3 lifecycle rules that can be used for buckets"
  value       = local.s3_lifecycle_rules
}

output "secretsmanager_secrets" {
  description = "Map of common secretsmanager secrets to create"
  value = {
    for key, value in local.secretsmanager_secrets : key => value if contains(local.secretsmanager_secrets_filter, key)
  }
}

output "security_groups" {
  description = "Map of common security_groupss to create"
  value = {
    for key, value in local.security_groups : key => value if contains(local.security_groups_filter, key)
  }
}

output "ssm_associations" {
  description = "Map of common ssm associations to create"
  value = {
    for key, value in local.ssm_associations : key => value if contains(local.ssm_associations_filter, key)
  }
}

output "ssm_documents" {
  description = "Map of common ssm documents to create"
  value = {
    for key, value in local.ssm_documents : key => value if contains(local.ssm_documents_filter, key)
  }
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

output "sqs_queues" {
  description = "Map of sqs_queues to create depending on options provided"
  value       = local.sqs_queues
}
