module "datasync_activation_nlb" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/alb/aws"
  version = "9.17.0"

  name = "datasync-activation"

  load_balancer_type    = "network"
  vpc_id                = module.connected_vpc.vpc_id
  subnets               = [module.connected_vpc.public_subnets[0]]
  create_security_group = false
  security_groups       = [module.datasync_activation_nlb_security_group.security_group_id]

  target_groups = {
    datasync = {
      name_prefix          = "ds-"
      protocol             = "TCP"
      port                 = 80
      target_type          = "ip"
      target_id            = local.environment_configuration.datasync_instance_private_ip
      deregistration_delay = 10
    }
  }

  listeners = {
    datasync = {
      port     = 80
      protocol = "TCP"
      forward = {
        target_group_key = "datasync"
      }
    }
  }

  tags = local.tags
}
