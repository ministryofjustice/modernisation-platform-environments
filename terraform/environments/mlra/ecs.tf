# # ------------------------------------------------------------------------------
# # ECS
# # ------------------------------------------------------------------------------
#
# module "mlra-ecs" {
#
#   source = "./modules/ecs"
#
#   subnet_set_name           = local.subnet_set_name
#   vpc_all                   = local.vpc_all
#   app_name                  = local.application_name
#   container_instance_type   = local.application_data.accounts[local.environment].container_instance_type
#   ami_image_id              = local.application_data.accounts[local.environment].ami_image_id
#   instance_type             = local.application_data.accounts[local.environment].instance_type
#   user_data                 = local.user_data
#   key_name                  = local.application_data.accounts[local.environment].key_name
#   task_definition           = local.task_definition
#   ec2_desired_capacity      = local.application_data.accounts[local.environment].ec2_desired_capacity
#   ec2_max_size              = local.application_data.accounts[local.environment].ec2_max_size
#   ec2_min_size              = local.application_data.accounts[local.environment].ec2_min_size
#   task_definition_volume    = local.application_data.accounts[local.environment].task_definition_volume
#   network_mode              = local.application_data.accounts[local.environment].network_mode
#   server_port               = local.application_data.accounts[local.environment].server_port
#   app_count                 = local.application_data.accounts[local.environment].app_count
#   ec2_ingress_rules         = local.ec2_ingress_rules
#   ec2_egress_rules          = local.ec2_egress_rules
#   lb_tg_arn                 = module.alb.target_group_arn
#   tags_common               = local.tags
#   appscaling_min_capacity   = local.application_data.accounts[local.environment].appscaling_min_capacity
#   appscaling_max_capacity   = local.application_data.accounts[local.environment].appscaling_max_capacity
#   ec2_scaling_cpu_threshold = local.application_data.accounts[local.environment].ec2_scaling_cpu_threshold
#   ec2_scaling_mem_threshold = local.application_data.accounts[local.environment].ec2_scaling_mem_threshold
#   ecs_scaling_cpu_threshold = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
#   ecs_scaling_mem_threshold = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
#
# }
#
# # MAAT DB Password
#
# data "aws_ssm_parameter" "db_password" {
#   name = local.application_data.accounts[local.environment].maat_db_password
# }
