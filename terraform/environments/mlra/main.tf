module "lb-access-logs-enabled" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer"
  providers = {
    aws.bucket-replication = aws
  }

  vpc_all = local.vpc_all
  #existing_bucket_name               = "my-bucket-name"
  application_name           = local.application_name
  public_subnets             = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id, data.aws_subnet.public_subnets_c.id]
  loadbalancer_egress_rules  = local.loadbalancer_egress_rules
  loadbalancer_ingress_rules = local.loadbalancer_ingress_rules
  tags                       = local.tags
  account_number             = local.environment_management.account_ids[terraform.workspace]
  region                     = local.application_data.accounts[local.environment].region
  enable_deletion_protection = false
  idle_timeout               = 60
}

locals {
  loadbalancer_ingress_rules = {
    "cluster_ec2_lb_ingress" = {
      description     = "Cluster EC2 loadbalancer ingress rule"
      from_port       = 32768
      to_port         = 61000
      protocol        = "tcp"
      cidr_blocks     = []
      security_groups = []
    },
    "cluster_c2_bastion_ingress" = {
      description     = "Cluster EC2 bastion ingress rule"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      cidr_blocks     = ["10.200.0.0/20"]
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
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

resource "aws_lb_target_group" "alb_target_group" {
  name        = "mlra-arget-group"
  #target_type = "alb"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.shared.id
}








