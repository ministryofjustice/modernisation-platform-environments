locals {
  # Used to create a map to use in ecs_load_balancer block for the ecs service module
  container_ports = [for _, v in var.container_port_config : tostring(v.containerPort)]
  ecs_nlbs = { for container_port in local.container_ports : container_port => {
    target_group_arn = aws_lb_target_group.service[container_port].arn
    container_name   = var.name
    container_port   = container_port
    }
  }
}
