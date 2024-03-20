locals {
  # Used to create a map to use in ecs_load_balancer block for the ecs service module
  container_ports = [for _, v in var.container_port_config : tostring(v.containerPort)]
  ecs_nlbs = { for container_port in local.container_ports : container_port => {
    target_group_arn = aws_lb_target_group.service[container_port].arn
    container_name   = var.name
    container_port   = container_port
    }
  }

  rds_env_vars = var.rds_endpoint_environment_variable != "" ? [{
    name  = var.rds_endpoint_environment_variable
    value = aws_db_instance.this[0].address
  }] : []

  rds_secrets = var.rds_password_secret_variable != "" ? [{
    name  = var.rds_password_secret_variable
    value = "${aws_db_instance.this[0].master_user_secret[0].secret_arn}:password:AWSCURRENT"
  }] : []

  elasticache_env_vars = var.elasticache_endpoint_environment_variable != "" ? [{
    name  = var.elasticache_endpoint_environment_variable
    value = aws_elasticache_cluster.this[0].cluster_address
  }] : []


}
