module "ldap_ecs" {
  source = "../helpers/delius_microservice"

  name     = "ldap"
  env_name = var.env_name

  container_cpu    = var.delius_microservice_configs.ldap.container_cpu
  container_memory = var.delius_microservice_configs.ldap.container_memory

  container_vars_default = {
    "LDAP_HOST"          = "0.0.0.0",
    "SLAPD_LOG_LEVEL"    = var.delius_microservice_configs.ldap.slapd_log_level,
    "LDAP_PORT"          = "389",
    "DELIUS_ENVIRONMENT" = "delius-core-${var.env_name}"
  }

  container_vars_env_specific = try(var.delius_microservice_configs.ldap.container_vars_env_specific, {})

  container_secrets_default = {
    "BIND_PASSWORD"         = aws_ssm_parameter.ldap_bind_password.arn,
    "MIGRATION_S3_LOCATION" = aws_ssm_parameter.ldap_seed_uri.arn,
    "RBAC_TAG"              = aws_ssm_parameter.ldap_rbac_version.arn
  }
  container_secrets_env_specific = try(var.delius_microservice_configs.ldap.container_secrets_env_specific, {})

  desired_count                      = var.ldap_config.desired_count
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  container_port_config = [
    {
      containerPort = var.delius_microservice_configs.ldap.container_port
      protocol      = "tcp"
    }
  ]

  system_controls = [
    {
      namespace = "net.ipv4.tcp_keepalive_time"
      value     = "300"
    }
  ]

  ecs_cluster_arn           = module.ecs.ecs_cluster_arn
  cluster_security_group_id = aws_security_group.cluster.id

  bastion_sg_id = module.bastion_linux.bastion_security_group
  tags          = var.tags

  platform_vars   = var.platform_vars
  container_image = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-openldap-ecr-repo:${var.delius_microservice_configs.ldap.image_tag}"
  account_config  = var.account_config

  container_health_check = {
    command     = ["CMD-SHELL", "test -f /tmp/ready"]
    interval    = 60                                                             # seconds between checks
    retries     = 5                                                              # number of failed checks before marking as unhealthy
    startPeriod = var.delius_microservice_configs.ldap.health_check_start_period # grace period after container start before checks begin
    timeout     = 5                                                              # seconds before checks time out
  }
  account_info = var.account_info

  ignore_changes_service_task_definition = false

  extra_task_exec_role_policies = {
    efs = data.aws_iam_policy_document.ldap_efs_access_policy
  }

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  log_error_pattern = "%${join("|", local.ldap_formatted_error_codes)}%"
  log_error_threshold_config = {
    warning = {
      threshold = 25
      period    = 300
    }
    critical = {
      threshold = 50
      period    = 300
    }
  }

  log_retention = var.ldap_config.log_retention

  sns_topic_arn           = aws_sns_topic.delius_core_alarms.arn
  enable_platform_backups = var.enable_platform_backups

  efs_volumes = [
    {
      host_path = null
      name      = "delius-core-openldap"
      efs_volume_configuration = [{
        file_system_id          = module.ldap.efs_fs_id
        root_directory          = "/"
        transit_encryption      = "ENABLED"
        transit_encryption_port = 2049
        authorization_config = [{
          access_point_id = module.ldap.efs_access_point_id
          iam             = "DISABLED"
        }]
      }]
    }
  ]

  mount_points = [{
    sourceVolume  = "delius-core-openldap"
    containerPath = "/var/lib/openldap/openldap-data"
    readOnly      = false
  }]

  ecs_service_egress_security_group_ids = [
    {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound traffic to any IPv4 address"
    }
  ]

  nlb_ingress_security_group_ids = [
    {
      port        = var.ldap_config.port
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_config.shared_vpc_cidr
      description = "Allow inbound traffic from VPC"
    },
    {
      port        = var.ldap_config.port
      ip_protocol = "udp"
      cidr_ipv4   = var.account_config.shared_vpc_cidr
      description = "Allow inbound traffic from VPC"
    },
    # Access is covered by above rule, using temp localhost CIDR so all rules aren't recreated/reordered
    {
      port        = var.ldap_config.port
      ip_protocol = "udp"
      # referenced_security_group_id = module.bastion_linux.bastion_security_group # Temporarily removed to recreate bastion SG
      cidr_ipv4   = "127.0.0.1/32"
      description = "Allow inbound traffic from bastion"
    },
    {
      port        = var.ldap_config.port
      ip_protocol = "tcp"
      cidr_ipv4   = var.environment_config.migration_environment_vpc_cidr
      description = "Allow inbound LDAP traffic from corresponding legacy VPC"
    },
    {
      port        = var.ldap_config.port
      ip_protocol = "udp"
      cidr_ipv4   = var.environment_config.migration_environment_vpc_cidr
      description = "Allow inbound LDAP traffic from corresponding legacy VPC"
    },
    {
      port        = var.ldap_config.port
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_info.cp_cidr
      description = "Allow inbound LDAP traffic from CP"
    },
    {
      port        = var.ldap_config.port
      ip_protocol = "udp"
      cidr_ipv4   = var.account_info.cp_cidr
      description = "Allow inbound LDAP traffic from CP"
    },
    {
      port                         = 2049
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.ldap.efs_sg_id
      description                  = "EFS ingress"
    },
    {
      port        = var.ldap_config.tls_port
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_config.shared_vpc_cidr
      description = "Allow inbound traffic from VPC"
    },
    {
      port        = var.ldap_config.tls_port
      ip_protocol = "udp"
      cidr_ipv4   = var.account_config.shared_vpc_cidr
      description = "Allow inbound traffic from VPC"
    },
    # Access is covered by above rule, using temp localhost CIDR so all rules aren't recreated/reordered
    {
      port        = var.ldap_config.tls_port
      ip_protocol = "udp"
      # referenced_security_group_id = module.bastion_linux.bastion_security_group # Temporarily removed to recreate bastion SG
      cidr_ipv4   = "127.0.0.1/32"
      description = "Allow inbound traffic from bastion"
    },
    {
      port        = var.ldap_config.tls_port
      ip_protocol = "tcp"
      cidr_ipv4   = var.environment_config.migration_environment_vpc_cidr
      description = "Allow inbound LDAP traffic from corresponding legacy VPC"
    },
    {
      port        = var.ldap_config.tls_port
      ip_protocol = "udp"
      cidr_ipv4   = var.environment_config.migration_environment_vpc_cidr
      description = "Allow inbound LDAP traffic from corresponding legacy VPC"
    },
    {
      port        = var.ldap_config.tls_port
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_info.cp_cidr
      description = "Allow inbound LDAP traffic from CP"
    },
    {
      port        = var.ldap_config.tls_port
      ip_protocol = "udp"
      cidr_ipv4   = var.account_info.cp_cidr
      description = "Allow inbound LDAP traffic from CP"
    },
  ]

  ecs_service_ingress_security_group_ids = [
    {
      port        = var.ldap_config.port
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_config.shared_vpc_cidr
      description = "Allow inbound traffic from VPC"
    },
    {
      port        = var.ldap_config.port
      ip_protocol = "udp"
      cidr_ipv4   = var.account_config.shared_vpc_cidr
      description = "Allow inbound traffic from VPC"
    },
    # Access is covered by above rule, using temp localhost CIDR so all rules aren't recreated/reordered
    {
      port        = var.ldap_config.port
      ip_protocol = "udp"
      # referenced_security_group_id = module.bastion_linux.bastion_security_group # Temporarily removed to recreate bastion SG
      cidr_ipv4   = "127.0.0.1/32"
      description = "Allow inbound traffic from bastion"
    },
    {
      port        = var.ldap_config.port
      ip_protocol = "tcp"
      cidr_ipv4   = var.environment_config.migration_environment_vpc_cidr
      description = "Allow inbound LDAP traffic from corresponding legacy VPC"
    },
    {
      port        = var.ldap_config.port
      ip_protocol = "udp"
      cidr_ipv4   = var.environment_config.migration_environment_vpc_cidr
      description = "Allow inbound LDAP traffic from corresponding legacy VPC"
    },
    {
      port        = var.ldap_config.port
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_info.cp_cidr
      description = "Allow inbound LDAP traffic from CP"
    },
    {
      port        = var.ldap_config.port
      ip_protocol = "udp"
      cidr_ipv4   = var.account_info.cp_cidr
      description = "Allow inbound LDAP traffic from CP"
    },
    {
      port                         = 2049
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.ldap.efs_sg_id
      description                  = "EFS ingress"
    }
  ]
}


data "aws_iam_policy_document" "ldap_efs_access_policy" {
  statement {
    actions = [
      "elasticfilesystem:ClientRootAccess",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientMount"
    ]
    resources = [
      module.ldap.efs_fs_arn
    ]
    effect = "Allow"
  }
}

locals {
  ldap_domain_types = { for dvo in aws_acm_certificate.ldap_external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }
  ldap_domain_name_main   = [for k, v in local.ldap_domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  ldap_domain_name_sub    = [for k, v in local.ldap_domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  ldap_domain_record_main = [for k, v in local.ldap_domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  ldap_domain_record_sub  = [for k, v in local.ldap_domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  ldap_domain_type_main   = [for k, v in local.ldap_domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  ldap_domain_type_sub    = [for k, v in local.ldap_domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]

  ldap_error_codes = [
    1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14,
    16, 17, 18, 19, 20, 21, 33, 34, 35, 36, 48, 49,
    50, 51, 52, 53, 54, 60, 61, 64, 65, 66, 67, 68,
    69, 70, 71, 76, 80, 81, 82, 83, 84, 85, 86, 87,
    88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 100, 101,
    112, 113, 114, 118, 119, 120, 121, 122, 123, 4096,
    16654
  ]
  ldap_formatted_error_codes = [for error_code in local.ldap_error_codes : "err=${error_code}\\s"]
}

resource "aws_lb_listener" "ldaps" {
  load_balancer_arn = module.ldap_ecs.nlb_arn
  port              = 636
  protocol          = "TLS"

  default_action {
    type             = "forward"
    target_group_arn = module.ldap_ecs.nlb_target_group_arn_map[389]
  }

  certificate_arn = aws_acm_certificate.ldap_external.arn
}

resource "aws_route53_record" "ldap_external" {
  provider = aws.core-vpc

  zone_id = var.account_config.route53_external_zone.zone_id
  name    = "ldap.${var.env_name}.${var.account_config.dns_suffix}"
  type    = "CNAME"
  ttl     = "60"
  records = [module.ldap_ecs.nlb_dns_name]
}

resource "aws_route53_record" "ldap_external_validation" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.ldap_domain_name_main[0]
  records         = local.ldap_domain_record_main
  ttl             = 60
  type            = local.ldap_domain_type_main[0]
  zone_id         = var.account_config.route53_network_services_zone.zone_id
}

resource "aws_acm_certificate" "ldap_external" {
  domain_name               = "modernisation-platform.service.justice.gov.uk"
  validation_method         = "DNS"
  subject_alternative_names = [aws_route53_record.ldap_external.name]
  tags                      = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "ldap_external_validation_subdomain" {
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.ldap_domain_name_sub[0]
  records         = local.ldap_domain_record_sub
  ttl             = 60
  type            = local.ldap_domain_type_sub[0]
  zone_id         = var.account_config.route53_external_zone.zone_id
}

resource "aws_acm_certificate_validation" "ldap_external" {
  certificate_arn         = aws_acm_certificate.ldap_external.arn
  validation_record_fqdns = [local.ldap_domain_name_main[0], local.ldap_domain_name_sub[0]]
}

resource "aws_cloudwatch_log_group" "ldap_automation" {
  name              = "/ecs/ldap-automation-${var.env_name}"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_cloudwatch_log_data_protection_policy" "ldap_automation" {
  log_group_name = aws_cloudwatch_log_group.ldap_automation.name

  policy_document = jsonencode({
    Name        = "data-protection-policy",
    Description = "",
    Version     = "2021-06-01",
    Statement = [
      {
        Sid = "audit-policy",
        DataIdentifier = [
          "MatchSshaHashes"
        ],
        Operation = {
          Audit = {
            FindingsDestination = {}
          }
        }
      },
      {
        Sid = "redact-policy",
        DataIdentifier = [
          "MatchSshaHashes"
        ],
        Operation = {
          Deidentify = {
            MaskConfig = {}
          }
        }
      }
    ],
    Configuration = {
      CustomDataIdentifier = [
        {
          Name  = "MatchSshaHashes",
          Regex = "{ssha}[A-Za-z0-9+/]+={0,2}"
        }
      ]
    }
  })
}
