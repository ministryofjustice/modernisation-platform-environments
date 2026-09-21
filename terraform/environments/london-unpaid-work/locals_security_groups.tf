locals {
  security_group_cidrs_by_environment = {
    development   = local.security_group_cidrs_development
    test          = local.security_group_cidrs_test
    preproduction = local.security_group_cidrs_preproduction
    production    = local.security_group_cidrs_production
  }
  security_group_cidrs = local.security_group_cidrs_by_environment[local.environment]

  security_groups = {
    london-unpaid-work-alb = {
      description = "London Unpaid Work application load balancer security group"
      ingress = {
        http_self = {
          description = "Allow ALB traffic from itself on HTTP"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          self        = true
        }
        https_self = {
          description = "Allow ALB traffic from itself on HTTPS"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          self        = true
        }
        http_bastion = {
          description = "Allow bastion access to the ALB on HTTP"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.bastion
        }
        https_bastion = {
          description = "Allow bastion access to the ALB on HTTPS"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.bastion
        }
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
          security_groups = []
        }
      }
    }

# PO-38 : Leaving LB ingress for web and api commented out for now
    london-unpaid-work-web = {
      description = "London Unpaid Work web server security group"
      # ingress = {
      #   http_alb = {
      #     description = "Allow ALB access to the web server on HTTP"
      #     from_port   = 80
      #     to_port     = 80
      #     protocol    = "tcp"
      #     cidr_blocks = local.security_group_cidrs.alb
      #   }
      #   https_alb = {
      #     description = "Allow ALB access to the web server on HTTPS"
      #     from_port   = 443
      #     to_port     = 443
      #     protocol    = "tcp"
      #     cidr_blocks = local.security_group_cidrs.alb
      #   }
      # }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
          security_groups = []
        }
      }
    }
    london-unpaid-work-api = {
      description = "London Unpaid Work API server security group"
      ingress = {
        # http_alb = {
        #   description = "Allow ALB access to the API server on HTTP"
        #   from_port   = 80
        #   to_port     = 80
        #   protocol    = "tcp"
        #   cidr_blocks = local.security_group_cidrs.alb
        # }
        # https_alb = {
        #   description = "Allow ALB access to the API server on HTTPS"
        #   from_port   = 443
        #   to_port     = 443
        #   protocol    = "tcp"
        #   cidr_blocks = local.security_group_cidrs.alb
        # }

        http_web = {
          description     = "Allow web server access to the API server on HTTP"
          from_port       = 80
          to_port         = 80
          protocol        = "tcp"
          security_groups = ["london-unpaid-work-web"]
        }
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
          security_groups = []
        }
      }
    }

  }
}
