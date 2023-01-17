output "aws_lb_target_group" {
  value       = aws_lb_target_group.this
  description = "map of created aws_lb_target_groups"
}

output "aws_lb_listener" {
  value       = aws_lb_listener.this
  description = "the aws_lb_listener object"
}
