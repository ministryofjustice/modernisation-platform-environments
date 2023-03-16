# module "baseline" {
#   source = "../../modules/baseline"

#   providers = {
#     aws                       = aws
#     aws.core-network-services = aws.core-network-services
#     aws.core-vpc              = aws.core-vpc
#   }

#   environment            = module.environment
#   ec2_autoscaling_groups = lookup(local.environment_config, "autoscaling_groups", {})
# }
