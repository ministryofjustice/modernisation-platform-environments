output "acm_certificates" {
  description = "map of acm_certificate module outputs corresponding to var.acm_certificates"
  value       = module.acm_certificate
}

output "backups" {
  description = "map of backups corresponding to var.backups"
  value = {
    for vault_key, vault_value in var.backups : vault_key => {
      vault = vault_key == "everything" ? data.aws_backup_vault.everything : aws_backup_vault.this[vault_key]
      plans = {
        for plan_key, plan_value in vault_value.plans : plan_key => {
          plan      = aws_backup_plan.this["${vault_key}-${plan_key}"]
          selection = aws_backup_selection.this["${vault_key}-${plan_key}"]
        }
      }
    }
  }
}

output "bastion_linux" {
  description = "See bastion_linux module github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux for more detail"
  value       = length(module.bastion_linux) == 1 ? module.bastion_linux[0] : null
}

output "cloudwatch_dashboards" {
  description = "map of cloudwatch_dashboard modules corresponding to var.cloudwatch_dashboards"
  value       = module.cloudwatch_dashboard
}

output "cloudwatch_log_groups" {
  description = "map of aws_cloudwatch_log_group resources"
  value       = aws_cloudwatch_log_group.this
}

output "cloudwatch_log_metric_filters" {
  description = "map of aws_cloudwatch_log_metric_filter resources"
  value       = aws_cloudwatch_log_metric_filter.this
}

output "cloudwatch_metric_alarms" {
  description = "map of aws_cloudwatch_metric_alarm resources"
  value       = aws_cloudwatch_metric_alarm.this
}

output "data_firehoses" {
  description = "map of data_firehose modules"
  value       = module.data_firehose
}

output "ec2_autoscaling_groups" {
  description = "map of ec2_autoscaling_group module outputs corresponding to var.ec2_autoscaling_groups"
  value       = module.ec2_autoscaling_group
}

output "ec2_instances" {
  description = "map of ec2_instance module outputs corresponding to var.ec2_instances"
  value       = module.ec2_instance
}

output "efs" {
  description = "map of efs module outputs corresponding to var.efs"
  value       = module.efs
}

output "fsx_windows" {
  description = "map of fsx_windows module outputs corresponding to var.fsx_windows"
  value       = module.fsx_windows
}

output "iam_policies" {
  description = "map of aws_iam_policy resources"
  value       = aws_iam_policy.this
}

output "iam_roles" {
  description = "map of aws_iam_role resources"
  value       = aws_iam_role.this
}

output "key_pairs" {
  description = "map of aws_key_pair resources"
  value       = aws_key_pair.this
}

output "lbs" {
  description = "map of loadbalancer module and lb_listeners corresponding to var.lbs"
  value = {
    for lb_key, lb_value in var.lbs : lb_key => merge(module.lb[lb_key], {
      listeners = {
        for key, value in lb_value.listeners : key => module.lb_listener["${lb_key}-${key}"]
      }
    })
  }
}

output "oam_links" {
  description = "map of aws_oam_link resources corresponding to var.oam_links"
  value       = aws_oam_link.this
}

output "oam_sinks" {
  description = "map of aws_oam_sink resources corresponding to var.oam_sinks"
  value       = aws_oam_sink.this
}

output "route53_resolvers_security_group" {
  description = "security group used for route53 resolvers"
  value       = length(aws_security_group.route53_resolver) != 0 ? aws_security_group.route53_resolver[0] : null
}

output "route53_resolvers" {
  description = "map of route53 resolvers and rules corresponding to var.route53_resolvers"
  value = {
    for resolver_key, resolver_value in var.route53_resolvers : resolver_key => merge(aws_route53_resolver_endpoint.this[resolver_key], {
      rules = {
        for rule_key, rule_value in resolver_value.rules : rule_key => aws_route53_resolver_rule.this["${resolver_key}-${rule_key}"]
      }
    })
  }
}

output "route53_zones" {
  description = "map of any created route53 zones"
  value       = aws_route53_zone.this
}

output "s3_buckets" {
  description = "map of s3_bucket outputs cooresponding to var.s3_buckets. Policies can be found in iam_policies output"
  value       = module.s3_bucket
}

output "secretsmanager" {
  description = "map of secretsmanager secrets and secret versions"
  value = {
    secrets = aws_secretsmanager_secret.this
    secret_versions = {
      for key, value in aws_secretsmanager_secret_version.fixed : key => {
        arn            = value.arn
        id             = value.id
        secret_id      = value.secret_id
        version_id     = value.version_id
        version_stages = value.version_stages
      }
    }
  }
}

output "security_groups" {
  description = "map of security groups corresponding to var.security_groups"
  value       = aws_security_group.this
}

output "schedule_alarms_lambda" {
  description = "schedule alarms lambda output"
  value       = module.schedule_alarms_lambda
}

output "sns_topics" {
  description = "map of aws_sns_topic resources corresponding to var.sns_topics"
  value       = aws_sns_topic.this
}

output "ssm_associations" {
  description = "map of aws_ssm_association resources corresponding to var.ssm_association"
  value       = aws_ssm_association.this
}

output "ssm_documents" {
  description = "map of aws_ssm_document resources corresponding to var.ssm_documents"
  value       = aws_ssm_document.this
}

output "ssm_parameters" {
  description = "map of security groups corresponding to var.ssm_parameters"
  value = merge(
    aws_ssm_parameter.fixed,
    aws_ssm_parameter.placeholder
  )
}
