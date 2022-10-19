#------------------------------------------------------------------------------
# ECS
#------------------------------------------------------------------------------

module "windows-ecs" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs"

  subnet_set_name         = local.subnet_set_name
  vpc_all                 = local.vpc_all
  app_name                = local.application_name
  container_instance_type = local.application_data.accounts[local.environment].container_instance_type
  environment             = local.environment
  ami_image_id            = local.application_data.accounts[local.environment].ami_image_id
  instance_type           = local.application_data.accounts[local.environment].instance_type
  user_data               = base64encode(data.template_file.launch-template.rendered)
  key_name                = local.application_data.accounts[local.environment].key_name
  task_definition         = data.template_file.task_definition.rendered
  ec2_desired_capacity    = local.application_data.accounts[local.environment].ec2_desired_capacity
  ec2_max_size            = local.application_data.accounts[local.environment].ec2_max_size
  ec2_min_size            = local.application_data.accounts[local.environment].ec2_min_size
  container_cpu           = local.application_data.accounts[local.environment].container_cpu
  container_memory        = local.application_data.accounts[local.environment].container_memory
  task_definition_volume  = local.application_data.accounts[local.environment].task_definition_volume
  network_mode            = local.application_data.accounts[local.environment].network_mode
  server_port             = local.application_data.accounts[local.environment].server_port
  app_count               = local.application_data.accounts[local.environment].app_count
  ec2_ingress_rules       = local.ec2_ingress_rules
  ec2_egress_rules        = local.ec2_egress_rules
  tags_common             = local.tags

  depends_on = [aws_lb_listener.alb_listener]
}

# Input for ECS module

data "template_file" "launch-template" {
  template = file("user_data.txt")
  vars = {
    AppEcsCluster = local.cluster_name
    pAppName  = local.application_name
  }
}

data "template_file" "task_definition" {
  template = file("task_definition.json")
  vars = {
    app_name = local.application_name
    ecr_url = local.application_data.accounts[local.environment].ecr_url
    docker_image_tag = local.application_data.accounts[local.environment].docker_image_tag
    #TODO cloudwatch_logs_group 
    region = local.application_data.accounts[local.environment].region
    maat_api_end_point = local.application_data.accounts[local.environment].maat_api_end_point
    maat_db_url = local.application_data.accounts[local.environment].maat_db_url
    maat_db_password = local.application_data.accounts[local.environment].maat_db_password
    maat_libra_wsdl_url = local.application_data.accounts[local.environment].maat_libra_wsdl_url
    sentry_env = local.environment

  }
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
}