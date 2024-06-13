output "target_group_name" {
  description = "Output ALB target group name to be picked up by module cwalarm"
  value       = aws_lb_target_group.alb_target_group.name
}

output "target_group_arn" {
  description = "Output ALB target group ARN to be picked up by module mlra-ecs"
  value       = aws_lb_target_group.alb_target_group.arn
}

output "target_group_arn_suffix" {
  description = "Output ALB target group ARN Suffix to be picked up by CloudWatch"
  value       = aws_lb_target_group.alb_target_group.arn_suffix
}

# output "loab_balancer_listener" {
#   value = aws_lb_listener.alb_listener
# }

output "athena_db" {
  value = aws_athena_database.lb-access-logs
}

output "security_group" {
  value = aws_security_group.lb
}

output "load_balancer" {
  value = aws_lb.loadbalancer
}

output "load_balancer_arn" {
  description = "Output ALB DNS name for CloudFront reference"
  value       = aws_lb.loadbalancer.dns_name
}

output "load_balancer_arn_suffix" {
  description = "Output ALB ARN Suffix for CloudWatch reference"
  value       = aws_lb.loadbalancer.arn_suffix
}

output "load_balancer_id" {
  description = "Output ALB id for CloudFront reference"
  value       = aws_lb.loadbalancer.id
}

output "cloudfront_alb_secret" {
  value       = data.aws_secretsmanager_secret_version.cloudfront.secret_string
  description = "The secret between ALB and CloudFront"
  sensitive   = true
}