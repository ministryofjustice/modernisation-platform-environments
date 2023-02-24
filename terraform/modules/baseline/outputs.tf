output "acm_certificates" {
  description = "map of acm_certificate module outputs corresponding to var.acm_certificates"
  value       = module.acm_certificate
}

output "bastion_linux" {
  description = "See bastion_linux module github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux for more detail"
  value       = length(module.bastion_linux) == 1 ? module.bastion_linux[0] : null
}

output "debug" {
  description = "Add anything you want to debug here, e.g. local variables"
  value = {
    s3_buckets_iam_policies = local.s3_buckets_iam_policies
  }
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

output "s3_buckets" {
  description = "map of s3_bucket outputs cooresponding to var.s3_buckets. Policies can be found in iam_policies output"
  value       = module.s3_bucket
}

output "security_groups" {
  description = "map of security groups corresponding to var.security_groups"
  value       = aws_security_group.this
}
