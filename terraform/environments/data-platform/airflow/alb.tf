locals {
  /* Two rules (HTTP redirect + HTTPS) per allowed CIDR */
  mwaa_alb_ingress_rules = merge([
    for name, cidr in local.environment_configuration.airflow_allowed_ingress_cidrs : {
      "${name}-http" = {
        from_port   = 80
        to_port     = 80
        ip_protocol = "tcp"
        description = "HTTP (redirect) from ${name}"
        cidr_ipv4   = cidr
      }
      "${name}-https" = {
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
        description = "HTTPS from ${name}"
        cidr_ipv4   = cidr
      }
    }
  ]...)
}

#trivy:ignore:AVD-AWS-0053: internet-facing so users can reach it, ingress is restricted to allowed CIDRs
module "mwaa_alb" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/alb/aws"
  version = "10.5.0"

  name    = "mwaa"
  vpc_id  = data.aws_vpc.dp_vpc.id
  subnets = data.aws_subnets.dp_public_subnets.ids

  security_group_ingress_rules = local.mwaa_alb_ingress_rules
  security_group_egress_rules = {
    mwaa_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS to MWAA webserver endpoint"
      cidr_ipv4   = data.aws_vpc.dp_vpc.cidr_block
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
      certificate_arn = module.acm_airflow.acm_certificate_arn

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
