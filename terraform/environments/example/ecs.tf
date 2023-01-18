module "ecs" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs/"

  subnet_set_name         = local.subnet_set_name
  vpc_all                 = local.vpc_all
  app_name                = local.application_name
  container_instance_type = local.application_data.accounts[local.environment].container_os_type
  ami_image_id            = local.application_data.accounts[local.environment].container_ami_image_id
  instance_type           = local.application_data.accounts[local.environment].container_instance_type
  user_data               = base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {}))
  key_name                = local.application_data.accounts[local.environment].container_key_name
  task_definition         = templatefile("${path.module}/templates/task_definition.json.tftpl", {})
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
  lb_tg_name              = aws_lb_target_group.target_group.name
  tags_common             = local.tags

  depends_on = [aws_lb_listener.external]
}

locals {
  ec2_ingress_rules = {
    "cluster_ec2_lb_ingress" = {
      description = "Cluster EC2 ingress rule"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [
      data.aws_vpc.shared.cidr_block]
      security_groups = []
    }
    "cluster_ec2_lb_ingress_2" = {
      description = "Cluster EC2 ingress rule 2"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = [
      data.aws_vpc.shared.cidr_block]
      security_groups = []
    }
  }
  ec2_egress_rules = {
    "cluster_ec2_lb_egress" = {
      description = "Cluster EC2 loadbalancer egress rule"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
      "0.0.0.0/0"]
      security_groups = []
    }
  }
}