output "lb_target_groups" {
  description = "map of aws_lb_target_group resources"
  value       = aws_lb_target_group.this
}

output "autoscaling_group_name" {
  description = "map of aws_autoscaling_group resources"
  value       = aws_autoscaling_group.this.name
}
