output "lb_target_groups" {
  description = "map of aws_lb_target_group resources"
  value       = aws_lb_target_group.this
}
