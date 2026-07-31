output "lb_arn" {
  value = aws_lb.alb.arn
}

output "lb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.target_group.arn
}
