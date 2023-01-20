output "lb_target_group_arns" {
  description = "list of lb_target_group arns linked to the autoscaling group"
  value       = local.lb_target_group_arns
}
