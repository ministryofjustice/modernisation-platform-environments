output "acm_certificates" {
  description = "map of acm_certificate module outputs corresponding to var.acm_certificates"
  value       = module.acm_certificate
}

output "bastion_linux" {
  description = "See bastion_linux module github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux for more detail"
  value       = length(module.bastion_linux) == 1 ? module.bastion_linux[0] : null
}

output "cloudwatch_log_groups" {
  description = "map of aws_cloudwatch_log_group resources"
  value       = aws_cloudwatch_log_group.this
}

output "ec2_autoscaling_groups" {
  description = "map of ec2_autoscaling_group module outputs corresponding to var.ec2_autoscaling_groups"
  value       = module.ec2_autoscaling_group
}

output "ec2_instances" {
  description = "map of ec2_instance module outputs corresponding to var.ec2_instances"
  value       = module.ec2_instance
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

output "security_groups" {
  description = "map of security groups corresponding to var.security_groups"
  value       = aws_security_group.this
}

output "ssm_parameters" {
  description = "map of security groups corresponding to var.ssm_parameters"
  value = merge(
    aws_ssm_parameter.fixed,
    aws_ssm_parameter.placeholder
  )
}
