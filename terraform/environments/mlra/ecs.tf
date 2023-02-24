# ------------------------------------------------------------------------------
# ECS
# ------------------------------------------------------------------------------

module "mlra-ecs" {

  source = "./modules/ecs"

  subnet_set_name           = local.subnet_set_name
  vpc_all                   = local.vpc_all
  app_name                  = local.application_name
  container_instance_type   = local.application_data.accounts[local.environment].container_instance_type
  ami_image_id              = local.application_data.accounts[local.environment].ami_image_id
  instance_type             = local.application_data.accounts[local.environment].instance_type
  user_data                 = local.user_data
  key_name                  = local.application_data.accounts[local.environment].key_name
  task_definition           = local.task_definition
  ec2_desired_capacity      = local.application_data.accounts[local.environment].ec2_desired_capacity
  ec2_max_size              = local.application_data.accounts[local.environment].ec2_max_size
  ec2_min_size              = local.application_data.accounts[local.environment].ec2_min_size
  task_definition_volume    = local.application_data.accounts[local.environment].task_definition_volume
  network_mode              = local.application_data.accounts[local.environment].network_mode
  server_port               = local.application_data.accounts[local.environment].server_port
  app_count                 = local.application_data.accounts[local.environment].app_count
  ec2_ingress_rules         = local.ec2_ingress_rules
  ec2_egress_rules          = local.ec2_egress_rules
  lb_tg_arn                 = module.alb.target_group_arn
  tags_common               = local.tags
  appscaling_min_capacity   = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity   = local.application_data.accounts[local.environment].appscaling_max_capacity
  ec2_scaling_cpu_threshold = local.application_data.accounts[local.environment].ec2_scaling_cpu_threshold
  ec2_scaling_mem_threshold = local.application_data.accounts[local.environment].ec2_scaling_mem_threshold
  ecs_scaling_cpu_threshold = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold

}

locals {
  ec2_ingress_rules = {
    "cluster_ec2_lb_ingress" = {
      description     = "Cluster EC2 ingress rule"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block]
      security_groups = []
    }
    "cluster_ec2_lb_ingress_2" = {
      description     = "Cluster EC2 ingress rule 2"
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block]
      security_groups = []
    }
    "cluster_ec2_lb_ingress_3" = {
      description     = "Cluster EC2 ingress rule 3"
      from_port       = 32768
      to_port         = 61000
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block]
      security_groups = [module.alb.security_group.id]
    }
    "cluster_ec2_lb_ingress_4" = {
      description     = "Cluster EC2 ingress rule 4"
      from_port       = 1521
      to_port         = 1521
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block]
      security_groups = [module.alb.security_group.id]
    }
  }
  ec2_egress_rules = {
    "cluster_ec2_lb_egress" = {
      description     = "Cluster EC2 loadbalancer egress rule"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }

  user_data = base64encode(templatefile("user_data.sh", {
    app_name = local.application_name
  }))

  task_definition = templatefile("task_definition.json", {
    app_name            = local.application_name
    ecr_url             = local.application_data.accounts[local.environment].ecr_url
    docker_image_tag    = local.application_data.accounts[local.environment].docker_image_tag
    region              = local.application_data.accounts[local.environment].region
    maat_api_end_point  = local.application_data.accounts[local.environment].maat_api_end_point
    maat_db_url         = local.application_data.accounts[local.environment].maat_db_url
    maat_db_password    = data.aws_ssm_parameter.db_password.value
    maat_libra_wsdl_url = local.application_data.accounts[local.environment].maat_libra_wsdl_url
    sentry_env          = local.environment
  })
}

# MAAT DB Password

data "aws_ssm_parameter" "db_password" {
  name = local.application_data.accounts[local.environment].maat_db_password
}
