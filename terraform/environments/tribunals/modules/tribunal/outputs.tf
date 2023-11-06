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

output "tribunals_lb" {
  description = "LB"
  value       = module.ecs_loadbalancer.tribunals_lb
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app-ecr-repo.repository_url
}
