# Internal NLB used purely to give Juniper (reached over Transit Gateway from
# its own AWS account) a fixed private IP to route to, since the ALB behind
# it can't hold one itself. One listener + target group per app, all
# forwarding straight through to that same ALB via an "alb" target type on
# that app's own port
# (https://docs.aws.amazon.com/elasticloadbalancing/latest/network/target-group-register-targets.html#target-type-alb).
module "nlb" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/alb/aws"
  version = "9.9.0"

  name               = "${var.nlb_name}-${var.environment}"
  load_balancer_type = "network"
  internal           = true

  vpc_id = var.vpc_id

  subnet_mapping = [
    for subnet_id in var.nlb_subnets_ids : {
      subnet_id            = subnet_id
      private_ipv4_address = lookup(var.private_ipv4_addresses, subnet_id, null)
    }
  ]

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  security_group_ingress_rules = {
    for name, app in var.apps : "${name}-from-juniper" => {
      from_port      = app.listener_port
      to_port        = app.listener_port
      ip_protocol    = "tcp"
      description    = "Juniper (via Transit Gateway) to yjsm ${name} NLB listener"
      prefix_list_id = var.ingress_prefix_list_id
    }
  }

  security_group_egress_rules = {
    for name, app in var.apps : "${name}-to-alb" => {
      from_port   = app.target_port
      to_port     = app.target_port
      ip_protocol = "tcp"
      description = "NLB to yjsm ${name} on the yjsm apps ALB"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    for name, app in var.apps : name => {
      port     = app.listener_port
      protocol = app.protocol
      forward = {
        target_group_key = name
      }
    }
  }

  target_groups = {
    for name, app in var.apps : name => {
      name        = "${var.target_group_name_prefix}-${name}"
      protocol    = "TCP"
      port        = app.target_port
      target_type = "alb"
      target_id   = var.target_alb_arn

      health_check = {
        enabled  = true
        protocol = "HTTP"
        path     = "/actuator/health"
        port     = "traffic-port"
        matcher  = "200"
      }
    }
  }

  tags = var.tags
}
