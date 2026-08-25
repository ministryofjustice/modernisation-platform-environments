#### Simple internal ALB, built with the modernisation-platform-terraform-loadbalancer module ####
#### Forwards to the test EC2 instance created in ec2.tf                                     ####

locals {
  alb_ingress_rules = {
    http = {
      description     = "Allow HTTP access from within the VPC"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block]
      security_groups = []
    }
  }

  alb_egress_rules = {
    http = {
      description     = "Allow HTTP to targets within the VPC"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block]
      security_groups = []
    }
  }
}

module "loadbalancer" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer?ref=b6eb14af13337cf54b948fe9a163e3a91f4a4442" # v5.2.0

  providers = {
    aws.bucket-replication = aws
  }

  application_name           = local.application_name
  vpc_all                    = local.vpc_all
  subnets                    = data.aws_subnets.shared-private.ids
  internal_lb                = true # keep the ALB internal - this is a sandbox account
  loadbalancer_ingress_rules = local.alb_ingress_rules
  loadbalancer_egress_rules  = local.alb_egress_rules
  account_number             = local.environment_management.account_ids[terraform.workspace]
  region                     = data.aws_region.current.name
  enable_deletion_protection = false
  access_logs                = true # creates an S3 bucket + Athena db/table to store and query ALB access logs
  force_destroy_bucket       = true # allows the access-logs bucket to be destroyed
  idle_timeout               = 60
  tags                       = local.tags
}

resource "aws_lb_target_group" "test" {
  #checkov:skip=CKV_AWS_261:"health_check block is defined below"
  name                 = "sprinkler-test-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    path                = "/"
    healthy_threshold   = 2
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 5
    matcher             = "200-499"
    timeout             = 5
  }

  tags = { Name = "sprinkler-test-tg" }
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.test.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2:"HTTP only - this is an internal ALB in a sandbox account"
  #checkov:skip=CKV_AWS_103:"HTTP only - this is an internal ALB in a sandbox account"
  load_balancer_arn = module.loadbalancer.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}
