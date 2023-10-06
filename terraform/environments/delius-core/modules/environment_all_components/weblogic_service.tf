module "weblogic_container" {
  source                   = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.59.0"
  container_name           = "${var.env_name}-weblogic"
  container_image          = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-weblogic-ecr-repo:${var.weblogic_config.frontend_image_tag}"
  container_memory         = 4096
  container_cpu            = 1024
  essential                = true
  readonly_root_filesystem = false
  environment = [
    {
      name  = "LDAP_PORT"
      value = local.ldap_port
    },
    {
      name  = "LDAP_HOST"
      value = aws_lb.ldap.dns_name
    }
  ]
  secrets = [
    {
      name      = "JDBC_URL"
      valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_jdbc_url.arn
    },
    {
      name      = "JDBC_PASSWORD"
      valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_jdbc_password.arn
    },
    {
      name      = "TEST_MODE"
      valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_test_mode.arn
    },
    {
      name      = "LDAP_PRINCIPAL"
      valueFrom = aws_ssm_parameter.delius_core_ldap_principal.arn
    },
    { name      = "LDAP_CREDENTIAL"
      valueFrom = aws_secretsmanager_secret.delius_core_ldap_credential.arn
    },
    {
      name      = "USER_CONTEXT"
      valueFrom = data.aws_ssm_parameter.delius_core_frontend_env_var_user_context.arn
    },
    {
      name      = "EIS_USER_CONTEXT"
      valueFrom = data.aws_ssm_parameter.delius_core_frontend_env_var_eis_user_context.arn
    }
  ]
  port_mappings = [
    {
      containerPort = var.weblogic_config.frontend_container_port
      hostPort      = var.weblogic_config.frontend_container_port
      protocol      = "tcp"
    },
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = aws_cloudwatch_log_group.delius_core_frontend_log_group.name
      "awslogs-region"        = "eu-west-2"
      "awslogs-stream-prefix" = var.weblogic_config.frontend_fully_qualified_name
    }
  }
}

module "weblogic_ecs_policies" {
  source       = "../ecs_policies"
  env_name     = var.env_name
  service_name = "weblogic"
  tags         = local.tags
}

module "weblogic_service" {
  source                    = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=c195026bcf0a1958fa4d3cc2efefc56ed876507e"
  container_definition_json = module.weblogic_container.json_map_encoded_list
  ecs_cluster_arn           = module.ecs.ecs_cluster_arn
  name                      = "weblogic"
  vpc_id                    = var.account_config.shared_vpc_id

  launch_type  = "FARGATE"
  network_mode = "awsvpc"

  task_cpu    = "1024"
  task_memory = "4096"

  # terraform will not let you use module.weblogic_ecs_policies.service_role.arn as it is not created yet and can't evaluate the count in this module
  service_role_arn   = "arn:aws:iam::${var.account_info.id}:role/${module.weblogic_ecs_policies.service_role.name}"
  task_role_arn      = "arn:aws:iam::${var.account_info.id}:role/${module.weblogic_ecs_policies.task_role.name}"
  task_exec_role_arn = "arn:aws:iam::${var.account_info.id}:role/${module.weblogic_ecs_policies.task_exec_role.name}"

  environment = var.env_name
  namespace   = var.app_name

  health_check_grace_period_seconds = 0

  ecs_load_balancers = [
    {
      target_group_arn = aws_lb_target_group.delius_core_frontend_target_group.id
      container_name   = "${var.env_name}-weblogic"
      container_port   = var.weblogic_config.frontend_container_port
    }
  ]

  security_group_ids = [aws_security_group.weblogic_service.id]

  subnet_ids = var.account_config.private_subnet_ids

  exec_enabled = true

  ignore_changes_task_definition = true
  redeploy_on_apply              = false
  force_new_deployment           = false
}

resource "aws_security_group" "weblogic_service" {
  name        = format("%s - Delius Core Weblogic service", var.env_name)
  description = "Security group for the ${var.env_name} weblogic service"
  vpc_id      = var.account_info.vpc_id
  tags        = local.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "delius_core_weblogic_to_db" {
  security_group_id            = aws_security_group.weblogic_service.id
  description                  = "weblogic service to db"
  from_port                    = var.delius_db_container_config.port
  to_port                      = var.delius_db_container_config.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.delius_db_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "delius_core_frontend_ldap_tcp" {
  security_group_id = aws_security_group.weblogic_service.id
  description       = "ingress from ldap server tcp"
  from_port         = local.ldap_port
  to_port           = local.ldap_port
  ip_protocol       = "tcp"
  cidr_ipv4         = var.account_config.shared_vpc_cidr
}

resource "aws_vpc_security_group_ingress_rule" "delius_core_frontend_ldap_udp" {
  security_group_id = aws_security_group.weblogic_service.id
  description       = "ingress from ldap server udp"
  from_port         = local.ldap_port
  to_port           = local.ldap_port
  ip_protocol       = "udp"
  cidr_ipv4         = var.account_config.shared_vpc_cidr
}


resource "aws_vpc_security_group_egress_rule" "delius_core_frontend_security_group_ldap_tcp" {
  security_group_id = aws_security_group.weblogic_service.id
  description       = "ldap tcp outbound from weblogic"
  ip_protocol       = "tcp"
  to_port           = local.ldap_port
  from_port         = local.ldap_port
  cidr_ipv4         = var.account_config.shared_vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "delius_core_frontend_security_group_ldap_udp" {
  security_group_id = aws_security_group.weblogic_service.id
  description       = "ldap udp outbound from weblogic"
  ip_protocol       = "udp"
  to_port           = local.ldap_port
  from_port         = local.ldap_port
  cidr_ipv4         = var.account_config.shared_vpc_cidr
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_weblogic" {
  security_group_id            = aws_security_group.weblogic_service.id
  description                  = "load balancer to weblogic frontend"
  from_port                    = var.weblogic_config.frontend_container_port
  to_port                      = var.weblogic_config.frontend_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
}

resource "aws_security_group_rule" "weblogic_allow_all_egress" {
  description       = "Allow all outbound traffic to any IPv4 address on 443"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.weblogic_service.id
}

resource "aws_security_group_rule" "weblogic_alb" {
  description       = "Allow inbound traffic from VPC"
  type              = "ingress"
  from_port         = var.weblogic_config.frontend_container_port
  to_port           = var.weblogic_config.frontend_container_port
  protocol          = "TCP"
  security_group_id = aws_security_group.ldap.id
  cidr_blocks       = [var.account_config.shared_vpc_cidr]
}

resource "aws_cloudwatch_log_group" "delius_core_frontend_log_group" {
  name              = var.weblogic_config.frontend_fully_qualified_name
  retention_in_days = 7
  tags              = local.tags
}
