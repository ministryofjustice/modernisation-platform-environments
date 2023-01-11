#------------------------------------------------------------------------------
# Web Application Firewall
#------------------------------------------------------------------------------

# resource "aws_wafv2_web_acl" "waf" {
# #TODO https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl
# }

# --- New load balancer ---
module "lb_internal_nomis" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer.git?ref=v2.1.0"
  count  = 0
  providers = {
    aws.bucket-replication = aws
  }

  account_number             = local.environment_management.account_ids[terraform.workspace]
  application_name           = "int-${local.application_name}"
  enable_deletion_protection = false
  idle_timeout               = "60"
  loadbalancer_egress_rules  = local.lb_internal_nomis_egress_rules
  loadbalancer_ingress_rules = local.lb_internal_nomis_ingress_rules
  public_subnets             = data.aws_subnets.private.ids
  region                     = local.region
  vpc_all                    = "${local.vpc_name}-${local.environment}"
  force_destroy_bucket       = true
  internal_lb                = true
  tags = merge(
    local.tags,
    {
      Name = "internal-loadbalancer"
    },
  )
}

locals {
  lb_internal_nomis_egress_rules = {
    lb_internal_nomis_egress_1 = {
      description     = "Allow all outbound"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }
  lb_internal_nomis_ingress_rules = {
    lb_internal_nomis_ingress_1 = {
      description     = "allow 443 inbound from PTTP devices"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = []
      cidr_blocks     = [local.cidrs.mojo_globalprotect_internal]
    }
    lb_internal_nomis_ingress_2 = {
      description     = "allow 443 inbound from Jump Server"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = [aws_security_group.jumpserver-windows.id]
      cidr_blocks     = []
    }
    lb_internal_nomis_ingress_3 = {
      description     = "allow 80 inbound from PTTP devices"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = []
      cidr_blocks     = [local.cidrs.mojo_globalprotect_internal]
    }
    lb_internal_nomis_ingress_4 = {
      description     = "allow 80 inbound from Jump Server"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [aws_security_group.jumpserver-windows.id]
      cidr_blocks     = []
    }
  }
}
