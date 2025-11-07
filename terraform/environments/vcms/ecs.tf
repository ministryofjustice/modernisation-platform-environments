module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v6.0.0"

  name = "vcms-${local.environment}-cluster"

  tags = local.tags
}

resource "aws_security_group" "cluster" {
  name_prefix = "ecs-cluster-${local.environment}"
  vpc_id      = local.account_config.shared_vpc_id
  description = "ECS cluster SG"
  lifecycle {
    create_before_destroy = true
  }
}

module "ecs_service" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=v6.0.0"

  container_definitions = module.container_definition.json_encoded_list
  cluster_arn           = module.ecs.ecs_cluster_arn
  name                  = "vcms-${local.environment}"

  task_cpu    = local.app_config.container_cpu
  task_memory = local.app_config.task_memory

  desired_count                      = local.app_config.desired_count
  deployment_maximum_percent         = local.app_config.deployment_maximum_percent
  deployment_minimum_healthy_percent = local.app_config.deployment_minimum_healthy_percent

  service_role_arn   = "arn:aws:iam::${local.account_info.id}:role/${aws_iam_role.service.name}"
  task_role_arn      = "arn:aws:iam::${local.account_info.id}:role/${aws_iam_role.task.name}"
  task_exec_role_arn = "arn:aws:iam::${local.account_info.id}:role/${aws_iam_role.task_exec.name}"

  health_check_grace_period_seconds = local.app_config.health_check_grace_period_seconds

  service_load_balancers = [
    {
      target_group_arn = aws_lb_target_group.frontend.arn
      container_name   = "vcms"
      container_port   = local.app_config.container_port
    }
  ]

  efs_volumes = [
    {
      host_path = null
      name      = "vcms"
      efs_volume_configuration = [{
        file_system_id          = aws_efs_file_system.vcms.id
        root_directory          = "/"
        transit_encryption      = "ENABLED"
        transit_encryption_port = 2049
        authorization_config = [{
          access_point_id = aws_efs_access_point.vcms.id
          iam             = "DISABLED"
        }]
      }]
    }
  ]

  security_groups = [aws_security_group.ecs_service.id]

  subnets = local.account_config.private_subnet_ids

  enable_execute_command = true

  tags = local.tags
}


module "container_definition" {
  source                   = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//container?ref=v6.0.0"
  name                     = "vcms"
  image                    = local.image_uri
  memory                   = 512
  cpu                      = 256
  essential                = true
  readonly_root_filesystem = false

  environment = [
    {
      name  = "REDIS_HOST"
      value = aws_elasticache_cluster.redis.cache_nodes[0].address
    },
    {
      name  = "REDIS_PORT"
      value = "6379"
    },
    {
      name  = "REDIS_DB"
      value = "0"
    },
    {
      name  = "REDIS_CACHE_DB"
      value = "1"
    },
    {
      name  = "DB_HOST"
      value = aws_db_instance.mariadb.address
    },
    {
      name  = "DB_PORT"
      value = "3306"
    },
    {
      name  = "DB_DATABASE"
      value = "vcms"
    },
    {
      name  = "DB_USERNAME"
      value = "vcms"
    }
  ]

  secrets = [
    {
      name      = "DB_PASSWORD",
      valueFrom = aws_ssm_parameter.db_password.arn
    }
  ]

  port_mappings = [
    {
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }
  ]
  mount_points = [
    {
      sourceVolume  = "vcms"
      containerPath = "/mnt/vcmsdocs"
      readOnly      = false
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = aws_cloudwatch_log_group.vcms.name
      "awslogs-region"        = "eu-west-2"
      "awslogs-stream-prefix" = "vcms"
    }
  }
}

resource "aws_cloudwatch_log_group" "vcms" {
  name              = "/ecs/vcms"
  retention_in_days = 14
  tags              = local.tags
}

resource "aws_security_group" "ecs_service" {
  name        = "vcms-ecs"
  description = "Security group for ECS service"
  vpc_id      = local.account_info.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}


