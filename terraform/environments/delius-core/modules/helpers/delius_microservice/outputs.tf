output "target_group_arn" {
  value = try(aws_lb_target_group.frontend[0].arn, null)
}

output "service_security_group_id" {
  value = aws_security_group.ecs_service.id
}

output "rds_password_secret_arn" {
  value = var.create_rds ? "${aws_db_instance.this[0].master_user_secret[0].secret_arn}:password:AWSCURRENT" : null
}

output "task_role_arn" {
  value = "arn:aws:iam::${var.account_info.id}:role/${module.ecs_policies.task_role.name}"
}

output "elasticache_endpoint" {
  value = var.create_elasticache ? aws_elasticache_cluster.this[0].cache_nodes[0].address : null
}

output "elasticache_port" {
  value = var.create_elasticache ? aws_elasticache_cluster.this[0].port : null
}


output "rds_endpoint" {
  value = var.create_rds ? aws_db_instance.this[0].address : null
}

output "rds_port" {
  value = var.create_rds ? aws_db_instance.this[0].port : null
}

output "nlb_arn" {
  value = try(aws_lb.delius_microservices[0].arn, null)
}

output "nlb_dns_name" {
  value = try(aws_lb.delius_microservices[0].dns_name, null)
}

output "nlb_target_group_arn_map" {
  value = {
    for k, v in aws_lb_target_group.service : k => v.arn
  }
}

output "nlb_service_r53_record" {
  value = try(aws_route53_record.services_nlb_r53_record[0].fqdn, null)
}

output "alarm_names" {
  value = [
    aws_cloudwatch_metric_alarm.ecs_cpu_critical,
    aws_cloudwatch_metric_alarm.ecs_cpu_warning,
    aws_cloudwatch_metric_alarm.ecs_desired_task_count_warning,
    aws_cloudwatch_metric_alarm.ecs_memory_critical,
    aws_cloudwatch_metric_alarm.ecs_memory_warning,
    try(aws_cloudwatch_metric_alarm.alb_response_code_5xx_critical[0], []),
    try(aws_cloudwatch_metric_alarm.alb_response_code_5xx_warning[0], []),
    try(aws_cloudwatch_metric_alarm.alb_response_time_critical[0], []),
    try(aws_cloudwatch_metric_alarm.ecs_error_critical[0], []),
    try(aws_cloudwatch_metric_alarm.ecs_healthy_hosts_fatal[0], []),
    try(aws_cloudwatch_metric_alarm.ecs_host_cpu_critical[0], []),
    try(aws_cloudwatch_metric_alarm.ecs_host_cpu_warning[0], []),
    try(aws_cloudwatch_metric_alarm.ecs_host_memory_critical[0], []),
    try(aws_cloudwatch_metric_alarm.ecs_host_memory_warning[0], []),
    try(aws_cloudwatch_metric_alarm.ecs_host_volume_usage_critical[0], []),
    try(aws_cloudwatch_metric_alarm.ecs_root_volume_usage_warning[0], [])
  ]
}