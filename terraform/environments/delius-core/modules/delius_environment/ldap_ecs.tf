module "ldap_ecs" {
  source = "../helpers/delius_microservice"

  name                  = "ldap"
  certificate_arn       = local.certificate_arn
  alb_security_group_id = aws_security_group.ancillary_alb_security_group.id
  env_name              = var.env_name

  container_vars_default = {
    "LDAP_HOST"          = "0.0.0.0",
    "SLAPD_LOG_LEVEL"    = var.delius_microservice_configs.ldap.slapd_log_level,
    "LDAP_PORT"          = "389",
    "DELIUS_ENVIRONMENT" = "delius-core-${var.env_name}"
  }

  container_vars_env_specific = try(var.delius_microservice_configs.ldap.container_vars_env_specific, {})

  container_secrets_default      = {
    "BIND_PASSWORD"         = aws_ssm_parameter.ldap_bind_password.arn,
    "MIGRATION_S3_LOCATION" = aws_ssm_parameter.ldap_seed_uri.arn,
    "RBAC_TAG"              = aws_ssm_parameter.ldap_rbac_version.arn
  }
  container_secrets_env_specific = try(var.delius_microservice_configs.ldap.container_secrets_env_specific, {})

  desired_count = 1

  container_port_config = [
    {
      containerPort = var.delius_microservice_configs.ldap.container_port
      protocol      = "tcp"
    }
  ]

  ecs_cluster_arn            = module.ecs.ecs_cluster_arn
  db_ingress_security_groups = []
  cluster_security_group_id  = aws_security_group.cluster.id

  bastion_sg_id                      = module.bastion_linux.bastion_security_group
  tags                               = var.tags
  #microservice_lb                    = aws_lb.delius_core_ancillary
  #microservice_lb_https_listener_arn = aws_lb_listener.ancillary_https.arn
  #alb_listener_rule_host_header = "ldap.${var.env_name}.${var.account_config.dns_suffix}"

  platform_vars           = var.platform_vars
  container_image         = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-openldap-ecr-repo:${var.delius_microservice_configs.ldap.image_tag}"
  account_config          = var.account_config

  health_check = {
    command     = ["CMD-SHELL", "ldapsearch -x -H ldap://localhost:389 -b '' -s base '(objectclass=*)' namingContexts"]
    interval    = 30
    retries     = 3
    startPeriod = 60
    timeout     = 5
  }
  account_info            = var.account_info

  ignore_changes_service_task_definition = false

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  log_error_pattern       = "ERROR"
  sns_topic_arn           = aws_sns_topic.delius_core_alarms.arn
  frontend_lb_arn_suffix  = aws_lb.delius_core_ancillary.arn_suffix
  enable_platform_backups = var.enable_platform_backups

  efs_volumes = [
    {
      host_path = null
      name      = "delius-core-openldap"
      efs_volume_configuration = [{
        file_system_id          = var.ldap_config.efs_id
        root_directory          = "/"
        transit_encryption      = "ENABLED"
        transit_encryption_port = 2049
        authorization_config = [{
          access_point_id = var.ldap_config.efs_access_point_id
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
    {
      port                          = var.ldap_config.port
      ip_protocol                   = "tcp"
      referenced_security_group_id  = module.bastion_linux.bastion_security_group
      description                   = "Allow inbound traffic from bastion"
    },
    {
      port                           = var.ldap_config.port
      ip_protocol                    = "udp"
      referenced_security_group_id   = module.bastion_linux.bastion_security_group
      description                    = "Allow inbound traffic from bastion"
    },
    {
      port        = var.ldap_config.port
      ip_protocol = "tcp"
      cidr_ipv4   = var.environment_config.migration_environment_private_cidr[0]
      description = "Allow inbound LDAP traffic from corresponding legacy VPC"
    },
    {
      port        = var.ldap_config.port
      ip_protocol = "udp"
      cidr_ipv4   = var.environment_config.migration_environment_private_cidr[0]
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
