##############################################
### Locals for ELB Module
##############################################
locals {
  loadbalancer_ingress_rules = {
    "cluster_ec2_lb_ingress" = {
      description = "allow access on HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["188.214.15.75/32", "192.168.5.101/32", "79.152.189.104/32", "179.50.12.212/32", "188.172.252.34/32", "194.33.192.0/25", "194.33.193.0/25", "194.33.196.0/25", "194.33.197.0/25", "195.59.75.0/24", "201.33.21.5/32", "213.121.161.112/28", "52.67.148.55/32", "54.94.206.111/32", "178.248.34.42/32", "178.248.34.43/32", "178.248.34.44/32", "178.248.34.45/32", "178.248.34.46/32", "178.248.34.47/32", "89.32.121.144/32", "185.191.249.100/32", "2.138.20.8/32", "18.169.147.172/32", "35.176.93.186/32", "18.130.148.126/32", "35.176.148.126/32", "51.149.250.0/24", "51.149.249.0/29", "194.33.249.0/29", "51.149.249.32/29", "194.33.248.0/29", "20.49.214.199/32", "20.49.214.228/32", "20.26.11.71/32", "20.26.11.108/32", "128.77.75.128/26", "194.33.200.0/21", "194.33.216.0/23", "194.33.218.0/24", "128.77.75.64/26"]

      security_groups = []
    }
  }

  loadbalancer_egress_rules = {
    "cluster_ec2_lb_egress" = {
      description     = "Open all outbound ports"
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
    matcher             = "200-499"
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