##############################################
### Data Source for CloudFront Managed Prefix List
####################################################
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}


##############################################
### Locals for ELB Module
##############################################
locals {
  loadbalancer_ingress_rules = {
    "lb_ingress" = {
      description     = "Loadbalancer ingress rule from CloudFront"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks     = []
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
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


##############################################
### ELB Instance for OAS Application Servers
##############################################
module "lb_access_logs_enabled" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer?ref=6f59e1ce47df66bc63ee9720b7c58993d1ee64ee"
  providers = {
    aws.bucket-replication = aws
  }
  vpc_all                    = "${local.vpc_name}-${local.environment}"
  force_destroy_bucket       = true # enables destruction of logging bucket
  application_name           = local.application_name
  public_subnets             = data.aws_subnets.shared-public.ids
  loadbalancer_ingress_rules = local.loadbalancer_ingress_rules
  loadbalancer_egress_rules  = local.loadbalancer_egress_rules
  account_number             = local.environment_management.account_ids[terraform.workspace]
  region                     = "eu-west-2"
  enable_deletion_protection = false
  idle_timeout               = 60

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} lb_module" }
  )

}

resource "aws_lb_target_group" "oas_ec2_target_group" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  name_prefix          = "oas-ec"
  port                 = 9500
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
  }

  health_check {
    path                = "/"
    port                = "9500"
    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 3
    matcher             = "200-399"
    timeout             = 5
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-ec2-target-group" }
  )
}

resource "aws_lb_target_group_attachment" "oas_ec2_attachment" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  target_group_arn = aws_lb_target_group.oas_ec2_target_group[0].arn
  target_id        = aws_instance.oas_app_instance_new[0].id
  port             = 9500
}




resource "aws_lb_listener" "https_listener" {
  #checkov:skip=CKV_AWS_103
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  depends_on        = [aws_acm_certificate_validation.external]
  load_balancer_arn = module.lb_access_logs_enabled.load_balancer.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.external[0].arn

  default_action {
    target_group_arn = aws_lb_target_group.oas_ec2_target_group[0].arn
    type             = "forward"
  }
}