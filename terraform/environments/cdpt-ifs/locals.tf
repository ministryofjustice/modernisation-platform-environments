locals {

  domain_types = { for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  domain_name_main   = [for k, v in local.domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  domain_name_sub    = [for k, v in local.domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  domain_record_main = [for k, v in local.domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  domain_record_sub  = [for k, v in local.domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  domain_type_main   = [for k, v in local.domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  domain_type_sub    = [for k, v in local.domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]

  ecr_url = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/cdpt-ifs-ecr-repo"

  user_data = base64encode(templatefile("user_data.txt", {
    cluster_name = "${local.application_name}-ecs-cluster"
  }))

  loadbalancer_ingress_rules = {
    "cluster_ec2_lb_ingress" = {
      description     = "allow access on HTTPS"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks     = ["188.214.15.75/32", "192.168.5.101/32", "79.152.189.104/32", "179.50.12.212/32", "188.172.252.34/32", "194.33.192.0/25", "194.33.193.0/25", "194.33.196.0/25", "194.33.197.0/25", "195.59.75.0/24", "201.33.21.5/32", "213.121.161.112/28", "52.67.148.55/32", "54.94.206.111/32", "178.248.34.42/32", "178.248.34.43/32", "178.248.34.44/32", "178.248.34.45/32", "178.248.34.46/32", "178.248.34.47/32", "89.32.121.144/32", "185.191.249.100/32", "2.138.20.8/32", "18.169.147.172/32", "35.176.93.186/32", "18.130.148.126/32", "35.176.148.126/32", "51.149.250.0/24", "51.149.249.0/29", "194.33.249.0/29", "51.149.249.32/29", "194.33.248.0/29", "20.49.214.199/32", "20.49.214.228/32", "20.26.11.71/32", "20.26.11.108/32", "128.77.75.128/26", "194.33.200.0/21", "194.33.216.0/23", "194.33.218.0/24", "128.77.75.64/26"]
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