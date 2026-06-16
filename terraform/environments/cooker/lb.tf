locals {
  loadbalancer_ingress_rules = {
    "cluster_ec2_lb_ingress_http" = {
      description     = "allow access on HTTP"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_blocks     = ["90.247.65.98/32"]
      security_groups = []
    }
    "cluster_ec2_lb_ingress" = {
      description     = "allow access on HTTPS"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks     = ["90.247.65.98/32"]
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

resource "aws_lakeformation_data_lake_settings" "lake_formation" {
  admins = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-plan",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-apply",
  ]

  parameters = {
    "CROSS_ACCOUNT_VERSION" = "4"
  }
}

module "lb_access_logs_enabled" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer?ref=43426f3146df7eee38eb4bf193459499b8d5fc2f" #vtesting
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
  tags                       = { Name = "lb_module" }

}

resource "aws_lb_listener" "http_access_logs_probe" {
  load_balancer_arn = module.lb_access_logs_enabled.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  # A fixed response is enough to make the ALB serve requests and emit access logs.
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "access logs enabled"
      status_code  = "200"
    }
  }
}

