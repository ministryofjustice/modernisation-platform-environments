# "moved" resources are necessary as we don't have the permissions to edit the state file
# All resources in alfresco.tf can be removed once they've been relocated to delius-alfresco for all envs
moved {
  from = module.alfresco_efs
  to   = module.alfresco_efs[0]
}

moved {
  from = module.alfresco_sfs_ecs
  to   = module.alfresco_sfs_ecs[0]
}

moved {
  from = data.aws_iam_policy_document.alfresco_efs_access_policy
  to   = data.aws_iam_policy_document.alfresco_efs_access_policy[0]
}

moved {
  from = aws_security_group.alfresco_sfs_alb
  to   = aws_security_group.alfresco_sfs_alb[0]
}

moved {
  from = aws_vpc_security_group_ingress_rule.alfresco_sfs_alb
  to   = aws_vpc_security_group_ingress_rule.alfresco_sfs_alb[0]
}

moved {
  from = aws_vpc_security_group_egress_rule.alfresco_sfs_alb
  to   = aws_vpc_security_group_egress_rule.alfresco_sfs_alb[0]
}

moved {
  from = aws_lb.alfresco_sfs
  to   = aws_lb.alfresco_sfs[0]
}

moved {
  from = aws_lb_listener.alfresco_sfs_listener_https
  to   = aws_lb_listener.alfresco_sfs_listener_https[0]
}


module "alfresco_efs" {
  count  = var.env_name != "poc" ? 1 : 0
  source = "../helpers/efs"

  name           = "alfresco"
  env_name       = var.env_name
  creation_token = "${var.env_name}-sfs"

  kms_key_arn                     = var.account_config.kms_keys.general_shared
  throughput_mode                 = "elastic"
  provisioned_throughput_in_mibps = null
  tags                            = var.tags
  enable_platform_backups         = false

  vpc_id       = var.account_config.shared_vpc_id
  subnet_ids   = var.account_config.private_subnet_ids
  vpc_cidr     = var.account_config.shared_vpc_cidr
  account_info = var.account_info
}

module "alfresco_sfs_ecs" {
  count  = var.env_name != "poc" ? 1 : 0
  source = "../helpers/delius_microservice"

  name     = "alfresco-sfs"
  env_name = var.env_name

  container_cpu    = var.delius_microservice_configs.sfs.container_cpu
  container_memory = var.delius_microservice_configs.sfs.container_memory

  container_vars_default = {
    "scheduler.content.age.millis" = 518400000 # 6 days
    "scheduler.cleanup.interval"   = 259200000 # 3 days
  }

  container_vars_env_specific = {}

  container_secrets_default      = {}
  container_secrets_env_specific = {}

  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  container_port_config = [
    {
      containerPort = 8099
      protocol      = "tcp"
    }
  ]

  microservice_lb                    = aws_lb.alfresco_sfs[0]
  microservice_lb_https_listener_arn = aws_lb_listener.alfresco_sfs_listener_https[0].arn

  alb_listener_rule_host_header = "alf-sfs.${var.env_name}.${var.account_config.dns_suffix}"

  target_group_protocol_version = "HTTP1"


  alb_health_check = {
    path                 = "/"
    healthy_threshold    = 5
    interval             = 30
    protocol             = "HTTP"
    unhealthy_threshold  = 5
    matcher              = "200-499"
    timeout              = 10
    grace_period_seconds = 180
  }

  ecs_cluster_arn           = module.ecs.ecs_cluster_arn
  cluster_security_group_id = aws_security_group.cluster.id

  bastion_sg_id = module.bastion_linux.bastion_security_group
  tags          = var.tags

  platform_vars   = var.platform_vars
  container_image = "ghcr.io/ministryofjustice/hmpps-delius-alfresco-shared-file-store:2.1.2-4"
  account_config  = var.account_config

  account_info = var.account_info

  ignore_changes_service_task_definition = true

  extra_task_exec_role_policies = {
    efs = data.aws_iam_policy_document.alfresco_efs_access_policy[0]
  }

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  log_error_pattern       = "%${join("|", local.ldap_formatted_error_codes)}%"
  sns_topic_arn           = aws_sns_topic.delius_core_alarms.arn
  enable_platform_backups = false
  frontend_lb_arn_suffix  = aws_lb.alfresco_sfs[0].arn_suffix

  efs_volumes = [
    {
      host_path = null
      name      = "sfs"
      efs_volume_configuration = [{
        file_system_id          = module.alfresco_efs[0].fs_id
        root_directory          = "/"
        transit_encryption      = "ENABLED"
        transit_encryption_port = 2049
        authorization_config = [{
          access_point_id = module.alfresco_efs[0].access_point_id
          iam             = "DISABLED"
        }]
      }]
    }
  ]

  mount_points = [{
    sourceVolume  = "sfs"
    containerPath = "/tmp/Alfresco"
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
      port        = 8099
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_config.shared_vpc_cidr
      description = "Allow inbound traffic from VPC"
    },
    {
      port        = 8099
      ip_protocol = "udp"
      cidr_ipv4   = var.account_config.shared_vpc_cidr
      description = "Allow inbound traffic from VPC"
    },
    {
      port        = 8099
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_info.cp_cidr
      description = "Allow inbound LDAP traffic from CP"
    },
    {
      port        = 8099
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

  ecs_service_ingress_security_group_ids = [
    {
      port        = 8099
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_config.shared_vpc_cidr
      description = "Allow inbound traffic from VPC"
    },
    {
      port        = 8099
      ip_protocol = "udp"
      cidr_ipv4   = var.account_config.shared_vpc_cidr
      description = "Allow inbound traffic from VPC"
    },
    {
      port        = 8099
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_info.cp_cidr
      description = "Allow inbound web traffic from CP"
    },
    {
      port        = 8099
      ip_protocol = "udp"
      cidr_ipv4   = var.account_info.cp_cidr
      description = "Allow inbound web traffic from CP"
    },
    {
      port                         = 2049
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.ldap.efs_sg_id
      description                  = "EFS ingress"
    }
  ]
}

data "aws_iam_policy_document" "alfresco_efs_access_policy" {
  count = var.env_name != "poc" ? 1 : 0
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

resource "aws_security_group" "alfresco_sfs_alb" {
  count       = var.env_name != "poc" ? 1 : 0
  name        = "${var.env_name}-alf-sfs-alb"
  description = "controls access to and from alfresco sfs load balancer"
  vpc_id      = var.account_config.shared_vpc_id
  tags        = local.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alfresco_sfs_alb" {
  for_each          = var.env_name != "poc" ? toset([var.account_info.cp_cidr, var.account_config.shared_vpc_cidr]) : []
  security_group_id = aws_security_group.alfresco_sfs_alb[0].id
  description       = "Access into alb over https"
  from_port         = "443"
  to_port           = "443"
  ip_protocol       = "tcp"
  cidr_ipv4         = each.key
}

resource "aws_vpc_security_group_egress_rule" "alfresco_sfs_alb" {
  count             = var.env_name != "poc" ? 1 : 0
  security_group_id = aws_security_group.alfresco_sfs_alb[0].id
  description       = "egress from alb to ecs cluster"
  ip_protocol       = "-1"
  cidr_ipv4         = var.account_config.shared_vpc_cidr
}

# internal application load balancer
resource "aws_lb" "alfresco_sfs" {
  count              = var.env_name != "poc" ? 1 : 0
  name               = "${var.app_name}-${var.env_name}-alf-sfs-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alfresco_sfs_alb[0].id]
  subnets            = var.account_config.private_subnet_ids

  enable_deletion_protection = false
  drop_invalid_header_fields = true
}

resource "aws_lb_listener" "alfresco_sfs_listener_https" {
  count             = var.env_name != "poc" ? 1 : 0
  load_balancer_arn = aws_lb.alfresco_sfs[0].id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = local.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
    }
  }
}
