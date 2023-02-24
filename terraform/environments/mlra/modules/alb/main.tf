# module "lb-access-logs-enabled" {
#   source = "../alb"
#   providers = {
#     aws.bucket-replication = aws.bucket-replication
#   }
#
#   vpc_all                    = var.vpc_all
#   internal_lb                = var.internal_lb
#   application_name           = var.application_name
#   public_subnets             = var.public_subnets
#   private_subnets            = var.private_subnets
#   region                     = var.region
#   enable_deletion_protection = var.enable_deletion_protection
#   idle_timeout               = var.idle_timeout
#   force_destroy_bucket       = var.force_destroy_bucket
#   tags                       = var.tags
#   account_number             = var.account_number
#   loadbalancer_ingress_rules = local.loadbalancer_ingress_rules
#   loadbalancer_egress_rules  = local.loadbalancer_egress_rules
# }

locals {
  loadbalancer_ingress_rules = {
    "lb_ingress" = {
      description     = "Loadbalancer ingress rule"
      from_port       = var.security_group_ingress_from_port
      to_port         = var.security_group_ingress_to_port
      protocol        = var.security_group_ingress_protocol
      cidr_blocks     = [var.ingress_cidr_block]
      security_groups = []
    }
    "lb_workspace_ingress" = {
      description     = "LB workspace ingress rule"
      from_port       = var.security_group_ingress_from_port
      to_port         = var.security_group_ingress_to_port
      protocol        = var.security_group_ingress_protocol
      cidr_blocks     = [var.lz_workspace_ingress_cidr]
      security_groups = []
    }
  }
  loadbalancer_egress_rules = {
    "lb_egress" = {
      description     = "Loadbalancer egress rule"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = var.listener_port
  #checkov:skip=CKV_AWS_2:The ALB protocol is HTTP
  protocol = var.listener_protocol #tfsec:ignore:aws-elb-http-not-used

  default_action {
    type = "forward"
    # during phase 1 of migration into modernisation platform, an effort
    # is being made to retain the current application url in order to
    # limit disruption to the application architecture itself. therefore,
    # the current laa alb which is performing tls termination is going to
    # forward queries on here. this also means that waf and cdn resources
    # are retained in laa. the cdn there adds a custom header to the query,
    # with the alb there then forwarding those permitted queries on:
    #
    # - Type: fixed-response
    #   FixedResponseConfig:
    #     ContentType: text/plain
    #     MessageBody: Access Denied - must access via CloudFront
    #     StatusCode: '403'
    #
    # in the meantime, therefore, we simply forward queries to a target
    # group. however, in another phase of the migration, where cdn resources
    # are carried into the modernisation platform, the above configuration
    # may need to be applied.
    #
    # see: https://docs.google.com/document/d/15BUaNNx6SW2fa6QNzdMUWscWWBQ44YCiFz-e3SOwouQ

    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

resource "aws_lb_listener_rule" "alb_listener_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn

  # during phase 1 of migration into modernisation platform, an effort
  # is being made to retain the current application url in order to
  # limit disruption to the application architecture itself. therefore,
  # the current laa alb which is performing tls termination is going to
  # forward queries on here. this also means that waf and cdn resources
  # are retained in laa. the cdn there adds a custom header to the query,
  # with the alb there then forwarding those permitted queries on:
  #
  # Actions:
  #   - Type: forward
  #     TargetGroupArn: !Ref 'TargetGroup'
  # Conditions:
  #   - Field: http-header
  #     HttpHeaderConfig:
  #     HttpHeaderName: X-Custom-Header-LAA-MLRA
  #     Values:
  #       - '{{resolve:secretsmanager:cloudfront-secret-MLRA}}'
  #
  # in the meantime, therefore, we are simply forwarding traffic to a
  # target group here. However, in another phase of the migration, where
  # cdn resources are carried into modernisation platform, the above
  # configuration is very likely going to be required.
  #
  # see: https://docs.google.com/document/d/15BUaNNx6SW2fa6QNzdMUWscWWBQ44YCiFz-e3SOwouQ

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_target_group" "alb_target_group" {
  name                 = "${var.application_name}-alb-tg"
  port                 = var.target_group_port
  protocol             = var.target_group_protocol
  vpc_id               = var.vpc_id
  deregistration_delay = var.target_group_deregistration_delay
  health_check {
    interval            = var.healthcheck_interval
    path                = var.healthcheck_path
    protocol            = var.healthcheck_protocol
    timeout             = var.healthcheck_timeout
    healthy_threshold   = var.healthcheck_healthy_threshold
    unhealthy_threshold = var.healthcheck_unhealthy_threshold
  }
  stickiness {
    enabled         = var.stickiness_enabled
    type            = var.stickiness_type
    cookie_duration = var.stickiness_cookie_duration
  }

  tags = {
    Name = "${var.application_name}-alb-tg"
  }

}
