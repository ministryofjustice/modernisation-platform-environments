module "mwaa_alb" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/alb/aws"
  version = "9.15.0"

  name    = "mwaa"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }
  listeners = {
    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.acm_certificate.acm_certificate_arn

      forward = {
        target_group_key = "mwaa"
      }
    }
  }
  target_groups = {
    mwaa = {
      name_prefix = "tg"
      protocol    = "HTTPS"
      port        = 443
      target_type = "ip"
      target_id   = data.dns_a_record_set.mwaa_webserver_vpc_endpoint.addrs[0]
      health_check = {
        enabled  = true
        path     = "/"
        port     = "traffic-port"
        protocol = "HTTPS"
        matcher  = "200,302"
      }
    }
  }
  additional_target_group_attachments = {
    mwaa = {
      target_group_key = "mwaa"
      target_id        = data.dns_a_record_set.mwaa_webserver_vpc_endpoint.addrs[1]
      port             = 443
    }
  }

  tags = local.tags
}
