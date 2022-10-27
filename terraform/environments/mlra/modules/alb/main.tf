module "lb-access-logs-enabled" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer"
  providers = {
    aws.bucket-replication = aws.bucket-replication
  }

  vpc_all                    = var.vpc_all
  application_name           = var.application_name
  public_subnets             = var.public_subnets
  region                     = var.region
  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout
  force_destroy_bucket       = var.force_destroy_bucket
  tags                       = var.tags
  account_number             = var.account_number
  loadbalancer_ingress_rules = local.loadbalancer_ingress_rules
  loadbalancer_egress_rules  = local.loadbalancer_egress_rules
}

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
  load_balancer_arn = module.lb-access-logs-enabled.load_balancer.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  #TODO CHANGE_TO_HTTPS_AND_CERTIFICATE_ARN_TOBE_ADDED

  default_action {
    type = "forward"
    #TODO default action type fixed-response has not been added
    #as this depends on cloudfront which is is not currently configured
    #therefore this will need to be added pending cutover strategy decisions
    #
    # - Type: fixed-response
    #   FixedResponseConfig:
    #     ContentType: text/plain
    #     MessageBody: Access Denied - must access via CloudFront
    #     StatusCode: '403'
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

# Forward action

resource "aws_lb_listener_rule" "alb_listener_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn

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

#TODO currently the EcsAlbHTTPSListenerRule has not been provisioned
#as this depends on cloudfront which is is not currently configured
#therefore this will need to be added pending cutover strategy decisions

resource "aws_lb_target_group" "alb_target_group" {
  name                 = "${var.application_name}-tg-${var.environment}"
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
}