output "launch_template_arn" {
  value = aws_launch_template.weblogic.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.weblogic.arn
}
