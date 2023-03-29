# Build ingress and egress rules
locals {
  loadbalancer_ingress_rules = {
    "cluster_ec2_lb_ingress" = {
      description     = "Cluster EC2 loadbalancer ingress rule"
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      cidr_blocks     = []
      security_groups = []
    },
    "cluster_ec2_bastion_ingress" = {
      description     = "Cluster EC2 bastion ingress rule"
      from_port       = 3389
      to_port         = 3389
      protocol        = "tcp"
      cidr_blocks     = []
      security_groups = []
    }
  }

  loadbalancer_egress_rules = {
    "cluster_ec2_lb_egress" = {
      description     = "Cluster EC2 loadbalancer egress rule"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }
}

# Load balancer build using the module
module "lb_access_logs_enabled" {
  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer?ref=v2.1.1"
  providers = {
    # Here we use the default provider for the S3 bucket module, buck replication is disabled but we still
    # Need to pass the provider to the S3 bucket module
    aws.bucket-replication = aws
  }
  vpc_all = "${local.vpc_name}-${local.environment}"
  #existing_bucket_name               = "my-bucket-name"
  force_destroy_bucket = true # enables destruction of logging bucket
  application_name     = local.application_name
  public_subnets = [
    data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id
  ]
  loadbalancer_ingress_rules = local.loadbalancer_ingress_rules
  loadbalancer_egress_rules  = local.loadbalancer_egress_rules
  tags                       = local.tags
  account_number             = local.environment_management.account_ids[terraform.workspace]
  region                     = "eu-west-2"
  enable_deletion_protection = false
  idle_timeout               = 60
}

# Create the target group
resource "aws_lb_target_group" "target_group_module_example" {
  name                 = "${local.application_name}-tg-module"
  port                 = 443
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }
  #checkov:skip=CKV_AWS_261: "health_check defined below, but not picked up"
  health_check {
    healthy_threshold   = "5"
    interval            = "120"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-tg-${local.environment}"
    }
  )
}

# Link target group to the EC2 instance on port 443
resource "aws_lb_target_group_attachment" "example_module_group_attachment" {
  target_group_arn = aws_lb_target_group.target_group_module_example.arn
  target_id        = aws_instance.develop.id
  port             = 443
}