# DSOS-109
module "jb_load_balancer_test" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer.git"
  count  = local.environment == "development" ? 1 : 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number             = local.modernisation_platform_account_id
  application_name           = "jbtest"
  enable_deletion_protection = false
  idle_timeout               = "60"
  loadbalancer_egress_rules  = local.jb_egress_rules
  loadbalancer_ingress_rules = local.jb_ingress_rules
  public_subnets             = []
  region                     = local.region
  vpc_all                    = local.vpc_id
  tags = merge(
    local.tags,
    {
      Name = "internal-loadbalancer"
    },
  )
}

locals {
  jb_egress_rules = {
    jb_internal_lb_egress_1 = {
      description     = "allow outbound to weblogic targets"
      from_port       = 7777
      to_port         = 7777
      protocol        = "tcp"
      security_groups = [aws_security_group.weblogic_common.id]
      cidr_blocks     = [""]
    }
  }
  jb_ingress_rules = {
    jb_internal_lb_ingress_1 = {
      description     = "allow 443 inbound from PTTP devices"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = [""]
      cidr_blocks     = ["10.184.0.0/16"] # Global Protect PTTP devices
    }
    jb_internal_lb_ingress_2 = {
      description     = "allow 443 inbound from Jump Server"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = [aws_security_group.jumpserver-windows.id]
      cidr_blocks     = [""]
    }
    jb_internal_lb_ingress_3 = {
      description     = "allow 80 inbound from PTTP devices"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [""]
      cidr_blocks     = ["10.184.0.0/16"] # Global Protect PTTP devices
    }
    jb_internal_lb_ingress_4 = {
      description     = "allow 80 inbound from Jump Server"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [aws_security_group.jumpserver-windows.id]
      cidr_blocks     = [""]
    }
  }
}