module "testing_db_container" {
  count                    = var.env_name == "dev" ? 1 : 0
  source                   = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.59.0"
  container_name           = "${var.env_name}-${var.delius_db_container_config.fully_qualified_name}"
  container_image          = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/${var.delius_db_container_config.image_name}-ecr-repo:${var.delius_db_container_config.image_tag}"
  container_memory         = 4096
  container_cpu            = 1024
  essential                = true
  readonly_root_filesystem = false
  port_mappings = [
    {
      containerPort = var.delius_db_container_config.port
      hostPort      = var.delius_db_container_config.port
      protocol      = "tcp"
    },
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = var.delius_db_container_config.fully_qualified_name
      "awslogs-region"        = "eu-west-2"
      "awslogs-stream-prefix" = var.delius_db_container_config.fully_qualified_name
    }
  }
}

module "db_ecs_policies" {
  count        = var.env_name == "dev" ? 1 : 0
  source       = "../ecs_policies"
  env_name     = var.env_name
  service_name = "testing-db"
  tags         = local.tags
}

module "testing_db_service" {
  count                     = var.env_name == "dev" ? 1 : 0
  source                    = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=5f488ac0de669f53e8283fff5bcedf5635034fe1"
  container_definition_json = module.weblogic_container.json_map_encoded_list
  ecs_cluster_arn           = module.ecs.ecs_cluster_arn
  name                      = "${var.env_name}-weblogic"
  vpc_id                    = var.network_config.shared_vpc_id

  launch_type  = "FARGATE"
  network_mode = "awsvpc"

  task_cpu    = "1024"
  task_memory = "4096"


  # terraform will not let you use module.weblogic_ecs_policies.service_role.arn as it is not created yet and can't evaluate the count in this module
  service_role_arn   = "arn:aws:iam::${var.account_info.id}:role/${module.db_ecs_policies[0].service_role.name}"
  task_role_arn      = "arn:aws:iam::${var.account_info.id}:role/${module.db_ecs_policies[0].task_role.name}"
  task_exec_role_arn = "arn:aws:iam::${var.account_info.id}:role/${module.db_ecs_policies[0].task_exec_role.name}"

  environment = var.env_name

  security_group_ids = [aws_security_group.weblogic.id]

  subnet_ids = var.network_config.private_subnet_ids

  exec_enabled = true

  ignore_changes_task_definition = false
  redeploy_on_apply              = false
  force_new_deployment           = false
}

resource "aws_route53_record" "delius-core-db" {
  count    = var.env_name == "dev" ? 1 : 0
  provider = aws.core-vpc
  zone_id  = var.network_config.route53_inner_zone_info.zone_id
  name     = "${var.app_name}-${var.env_name}-${var.delius_db_container_config.fully_qualified_name}.${var.network_config.route53_inner_zone_info.name}"
  type     = "A"
  ttl      = 300
  records  = ["10.26.25.119"]
}

resource "aws_security_group" "delius_db_security_group" {
  name        = "Delius Core DB"
  description = "Rules for the delius testing db ecs service"
  vpc_id      = var.network_config.shared_vpc_id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "delius_db_security_group_ingress_private_subnets" {
  security_group_id            = aws_security_group.delius_db_security_group.id
  description                  = "weblogic to testing db"
  from_port                    = var.delius_db_container_config.port
  to_port                      = var.delius_db_container_config.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.delius_core_frontend_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "delius_db_security_group_ingress_bastion" {
  security_group_id            = aws_security_group.delius_db_security_group.id
  description                  = "bastion to testing db"
  from_port                    = var.delius_db_container_config.port
  to_port                      = var.delius_db_container_config.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.bastion.security_group_id
}

resource "aws_vpc_security_group_egress_rule" "delius_db_security_group_egress_internet" {
  security_group_id = aws_security_group.delius_db_security_group.id
  description       = "outbound from the testing db ecs service"
  ip_protocol       = "tcp"
  to_port           = 443
  from_port         = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_cloudwatch_log_group" "delius_core_testing_db_log_group" {
  name              = var.delius_db_container_config.fully_qualified_name
  retention_in_days = 7
  tags              = local.tags
}
