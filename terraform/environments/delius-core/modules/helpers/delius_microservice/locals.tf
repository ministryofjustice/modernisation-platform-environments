locals {
  # Used to create a map to use in ecs_load_balancer block for the ecs service module
  container_ports = [for _, v in var.container_port_config : tostring(v.containerPort)]
  ecs_nlbs = { for container_port in local.container_ports : container_port => {
    target_group_arn = aws_lb_target_group.service[container_port].arn
    container_name   = var.name
    container_port   = container_port
    }
  }

  calculated_container_secrets = merge(
    var.container_secrets_default,
    var.container_secrets_env_specific,
    local.rds_secrets
    # local.elasticache_secrets
  )

  calculated_container_secrets_list = flatten([
    for key, value in local.calculated_container_secrets : [
      {
        name      = key
        valueFrom = value
      }
    ]
  ])

  calculated_container_vars = merge(
    var.container_vars_default,
    var.container_vars_env_specific,
    local.rds_env_vars,
    local.elasticache_endpoint_env_var
    # local.elasticache_user_env_var
  )

  calculated_container_vars_list = flatten([
    for key, value in local.calculated_container_vars : [
      {
        name  = key
        value = value
      }
    ]
  ])

  rds_env_vars = var.rds_endpoint_environment_variable != "" ? {
    (var.rds_endpoint_environment_variable) = aws_db_instance.this[0].endpoint
  } : {}

  rds_secrets = var.rds_password_secret_variable != "" ? {
    (var.rds_password_secret_variable) = "${aws_db_instance.this[0].master_user_secret[0].secret_arn}:password::"
    # tflint-ignore: terraform_map_duplicate_keys
    (var.rds_user_secret_variable) = "${aws_db_instance.this[0].master_user_secret[0].secret_arn}:username::"
  } : {}

  elasticache_endpoint_env_var = var.elasticache_endpoint_environment_variable != "" ? {
    (var.elasticache_endpoint_environment_variable) = aws_elasticache_cluster.this[0].cache_nodes[0].address
  } : {}

  # elasticache_user_env_var = var.elasticache_user_variable != "" ? {
  #   (var.elasticache_user_variable) = var.name
  # } : {}

  # elasticache_secrets = var.elasticache_password_secret_variable != "" ? {
  #   (var.elasticache_password_secret_variable) = module.elasticache_default_user_password.secret.arn
  # } : {}

}
