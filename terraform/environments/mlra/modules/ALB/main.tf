module "lb-access-logs-enabled" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer"
  providers = {
    aws.bucket-replication = aws
  }

  vpc_all                    = local.vpc_all
  application_name           = local.application_name
  public_subnets             = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id, data.aws_subnet.public_subnets_c.id]
  loadbalancer_egress_rules  = local.loadbalancer_egress_rules
  loadbalancer_ingress_rules = local.loadbalancer_ingress_rules
  tags                       = local.tags
  account_number             = local.environment_management.account_ids[terraform.workspace]
  region                     = local.application_data.accounts[local.environment].region
  enable_deletion_protection = false
  idle_timeout               = 60
  force_destroy_bucket       = true
}

locals {
  loadbalancer_ingress_rules = {
    "cluster_ec2_lb_ingress" = {
      description     = "Cluster EC2 loadbalancer ingress rule"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block]
      security_groups = []
    }
  }
  loadbalancer_egress_rules = {
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

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = module.lb-access-logs-enabled.load_balancer.arn
  port              = "443"
  protocol          = "HTTP"
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

#TODO currently the EcsAlbHTTPSListenerRule has not been provisioned
#as this depends on cloudfront which is is not currently configured
#therefore this will need to be added pending cutover strategy decisions

resource "aws_lb_target_group" "alb_target_group" {
  name                 = "${local.application_name}-target-group"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  deregistration_delay = 30
  health_check {
    interval            = 15
    path                = local.application_data.accounts[local.environment].alb_target_group_path
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 10800
  }
}