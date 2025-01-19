output "alb_name" {
  value = var.alb_name
}

output "alb_id" {
  value = module.alb.id
}

output "dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.dns_name
}

output "alb_arn" {
  value = module.alb.arn
}

output "alb_security_group_id" {
  value = module.alb_sg.security_group_id
}

output "alb_security_group_name" {
  value = module.alb_sg.security_group_name
}

output "target_group_arns" {
  value = { for k, tg in aws_lb_target_group.this : k => tg.arn }
}
