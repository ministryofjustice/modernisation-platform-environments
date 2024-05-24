output "target_group_arn" {
  value = aws_lb_target_group.frontend.arn
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
