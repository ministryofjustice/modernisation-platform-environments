locals {
  ##
  # Variables used across multiple areas
  ##
  app_url = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"

  app_port = 5000

  ##
  # Variables related to ECS module
  ##
  lb_tg_name = "${local.application_name}-tg-${local.environment}"

  ec2_ingress_rules = {
    "cluster_ec2_lb_ingress" = {
      description     = "Cluster EC2 loadbalancer ingress rule"
      from_port       = local.app_port
      to_port         = local.app_port
      protocol        = "tcp"
      cidr_blocks     = []
      security_groups = [aws_security_group.load_balancer_security_group.id]
    }
  }

  ec2_egress_rules = {
    "cluster_ec2_lb_rds_egress" = {
      description     = "Cluster EC2 loadbalancer egress rule"
      from_port       = 1433
      to_port         = 1433
      protocol        = "tcp"
      cidr_blocks     = [data.aws_subnet.data_subnets_a.cidr_block, data.aws_subnet.data_subnets_b.cidr_block, data.aws_subnet.data_subnets_c.cidr_block]
      security_groups = null
    },
    "cluster_ec2_lb_https_egress" = {
      description     = "Allow 443 to internet"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = null
    }
  }

  ecr_repo_name = "delius-jitbit-ecr-repo"
  ecr_uri       = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.ecr_repo_name}"

  task_definition = templatefile("${path.module}/templates/task_definition.json", {
    APP_NAME                                = local.application_name,
    DOCKER_IMAGE                            = "${local.ecr_uri}:latest"
    DATABASE_PASSWORD_CONNECTION_STRING_ARN = aws_secretsmanager_secret.db_app_connection_string.arn
    APP_URL                                 = "https://${local.app_url}/"
  })

  ##
  # Variables used by certificate validation, as part of the load balancer listener, cert and route 53 record configuration
  ##
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
}
