locals {
  # API ALB Ingress Rules - Used in loadbalancer.tf by MP module
  api_lb_ingress_rules = {
    "https-cloud-platform" = {
      description     = "Allow HTTPS from MoJ Cloud Platform"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = []
      cidr_blocks     = [module.ip_addresses.moj_cidr.aws_cloud_platform_vpc]
    }
  }

  # API ALB Egress Rules - Used in loadbalancer.tf by MP module
  api_lb_egress_rules = {
    "to-ecs" = {
      description     = "Allow outbound to ECS tasks on the application port"
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block]
      security_groups = []
    }
  }

  # Visualiser ALB Ingress Rules - Used in loadbalancer.tf by MP module
  # Rules managed in security_group.tf instead of locals.tf because loadbalancer.tf module does not support prefix lists
  visualiser_lb_ingress_rules = {}

  # Visualiser ALB Egress Rules - Used in loadbalancer.tf by MP module
  visualiser_lb_egress_rules = {
    "to-ecs" = {
      description     = "Allow outbound to ECS tasks on the application port"
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block]
      security_groups = []
    }
  }
}
