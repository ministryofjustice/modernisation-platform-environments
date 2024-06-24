output "tribunals_lb_sc_id" {
  description = "LB Security Group Id"
  value       = module.ecs_loadbalancer.tribunals_lb_sc_id
}

output "tribunals_target_group_arn" {
  description = "LB Target Group arn"
  value       = module.ecs_loadbalancer.tribunals_target_group_arn
}

output "tribunals_lb_listener" {
  description = "LB Listener"
  value       = module.ecs_loadbalancer.tribunals_lb_listener
}
