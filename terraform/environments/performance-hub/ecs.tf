#------------------------------------------------------------------------------
# ECS
#------------------------------------------------------------------------------

# module "windows-ecs" {

#   source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs?ref=v2.1.0"

#   subnet_set_name         = local.subnet_set_name
#   vpc_all                 = local.vpc_all
#   app_name                = local.application_name
#   container_instance_type = local.app_data.accounts[local.environment].container_instance_type
#   environment             = local.environment
#   ami_image_id            = local.app_data.accounts[local.environment].ami_image_id
#   instance_type           = local.app_data.accounts[local.environment].instance_type
#   user_data               = base64encode(data.template_file.launch-template.rendered)
#   key_name                = local.app_data.accounts[local.environment].key_name
#   task_definition         = data.template_file.task_definition.rendered
#   ec2_desired_capacity    = local.app_data.accounts[local.environment].ec2_desired_capacity
#   ec2_max_size            = local.app_data.accounts[local.environment].ec2_max_size
#   ec2_min_size            = local.app_data.accounts[local.environment].ec2_min_size
#   container_cpu           = local.app_data.accounts[local.environment].container_cpu
#   container_memory        = local.app_data.accounts[local.environment].container_memory
#   task_definition_volume  = local.app_data.accounts[local.environment].task_definition_volume
#   network_mode            = local.app_data.accounts[local.environment].network_mode
#   server_port             = local.app_data.accounts[local.environment].server_port
#   app_count               = local.app_data.accounts[local.environment].app_count
#   ec2_ingress_rules       = local.ec2_ingress_rules
#   ec2_egress_rules        = local.ec2_egress_rules
#   tags_common             = local.tags

#   depends_on = [aws_lb_listener.listener]
# }

module "windows-new-ecs" {

  source = "./module/ecs"

  subnet_set_name         = local.subnet_set_name
  vpc_all                 = local.vpc_all
  app_name                = local.application_name
  container_instance_type = local.app_data.accounts[local.environment].container_instance_type
  environment             = local.environment
  ami_image_id            = local.app_data.accounts[local.environment].ami_image_id
  instance_type           = local.app_data.accounts[local.environment].instance_type
  user_data               = base64encode(data.template_file.launch-template.rendered)
  key_name                = local.app_data.accounts[local.environment].key_name
  task_definition         = data.template_file.task_definition.rendered
  ec2_desired_capacity    = local.app_data.accounts[local.environment].ec2_desired_capacity
  ec2_max_size            = local.app_data.accounts[local.environment].ec2_max_size
  ec2_min_size            = local.app_data.accounts[local.environment].ec2_min_size
  container_cpu           = local.app_data.accounts[local.environment].container_cpu
  container_memory        = local.app_data.accounts[local.environment].container_memory
  task_definition_volume  = local.app_data.accounts[local.environment].task_definition_volume
  network_mode            = local.app_data.accounts[local.environment].network_mode
  server_port             = local.app_data.accounts[local.environment].server_port
  app_count               = local.app_data.accounts[local.environment].app_count
  ec2_ingress_rules       = local.ec2_ingress_rules
  ec2_egress_rules        = local.ec2_egress_rules
  tags_common             = local.tags

  depends_on = [aws_lb_listener.listener]
}

moved {
  from = module.windows-ecs
  to   = module.windows-new-ecs

}