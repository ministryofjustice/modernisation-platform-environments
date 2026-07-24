locals {
  # EFS volume config
  ecs_efs_volume = [{
    host_path = null
    name      = "dms-efs"
    efs_volume_configuration = [{
      file_system_id          = aws_efs_file_system.efs.id
      root_directory          = null
      transit_encryption      = "ENABLED"
      transit_encryption_port = null
      authorization_config = [{
        access_point_id = aws_efs_access_point.ecs.id
        iam             = "DISABLED"
      }]
    }]
  }]

  # All services 
  ecs_worker_services = toset([
    "blocking",
    "cleanup",
    "dbinteractions",
    "delius-parser",
    "filesync",
    "import",
    "logging",
    "matching-engine",
    "meow",
    "offloc-cleaner",
    "offloc-parser",
  ])

  # Services that require EFS mount points
  ecs_efs_services = toset([
    "cleanup",
    "dbinteractions",
    "delius-parser",
    "filesync",
    "offloc-cleaner",
    "offloc-parser",
  ])

  # Placeholder image - GitHub Actions replaces with real images during build
  placeholder_image = "public.ecr.aws/amazonlinux/amazonlinux:2023"
}

# MP Cluster Module - https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster/tree/main/cluster
module "ecs-cluster" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v6.0.2"

  name = "${local.application_name_short}-${local.environment}-cluster"
  tags = local.tags
}

# MP Container Module - https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster/tree/main/container
module "container_definition_api" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//container?ref=v6.0.2"

  name                     = "api-container"
  image                    = local.placeholder_image
  cpu                      = 512
  memory                   = 1024
  essential                = true
  readonly_root_filesystem = false
  environment              = []
  secrets                  = []
  port_mappings            = [{ containerPort = 8080, protocol = "tcp" }]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
      "awslogs-region"        = "eu-west-2"
      "awslogs-stream-prefix" = "api"
    }
  }
}

module "container_definition_visualiser" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//container?ref=v6.0.2"

  name                     = "visualiser-container"
  image                    = local.placeholder_image
  cpu                      = 512
  memory                   = 1024
  essential                = true
  readonly_root_filesystem = false
  environment              = []
  secrets                  = []
  port_mappings            = [{ containerPort = 8080, protocol = "tcp" }]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
      "awslogs-region"        = "eu-west-2"
      "awslogs-stream-prefix" = "visualiser"
    }
  }
}

module "container_definition_worker" {
  for_each = local.ecs_worker_services
  source   = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//container?ref=v6.0.2"

  name                     = "${each.key}-container"
  image                    = local.placeholder_image
  cpu                      = 512
  memory                   = 1024
  essential                = true
  readonly_root_filesystem = false
  environment              = []
  secrets                  = []
  port_mappings            = []
  mount_points = contains(local.ecs_efs_services, each.key) ? [{
    sourceVolume  = "dms-efs"
    containerPath = "/mnt/efs"
    readOnly      = false
  }] : null
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
      "awslogs-region"        = "eu-west-2"
      "awslogs-stream-prefix" = each.key
    }
  }
}

# MP Service Module - https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster/tree/main/service
module "ecs_service_api" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=v6.0.2"

  name                  = "${local.application_name_short}-${local.environment}-api"
  cluster_arn           = module.ecs-cluster.ecs_cluster_arn
  container_definitions = module.container_definition_api.json_encoded_list
  task_cpu              = "512"
  task_memory           = "1024"
  task_role_arn         = aws_iam_role.task.arn
  task_exec_role_arn    = aws_iam_role.execution.arn
  service_role_arn      = aws_iam_role.execution.arn
  security_groups       = [aws_security_group.ecs.id]
  subnets               = data.aws_subnets.shared-private.ids
  enable_execute_command = true
  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }
  service_load_balancers = [{
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api-container"
    container_port   = 8080
  }]
  tags                   = local.tags
}

module "ecs_service_visualiser" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=v6.0.2"

  name                  = "${local.application_name_short}-${local.environment}-visualiser"
  cluster_arn           = module.ecs-cluster.ecs_cluster_arn
  container_definitions = module.container_definition_visualiser.json_encoded_list
  task_cpu              = "512"
  task_memory           = "1024"
  task_role_arn         = aws_iam_role.task.arn
  task_exec_role_arn    = aws_iam_role.execution.arn
  service_role_arn      = aws_iam_role.execution.arn
  security_groups       = [aws_security_group.ecs.id]
  subnets               = data.aws_subnets.shared-private.ids
  enable_execute_command = true
  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }
  service_load_balancers = [{
    target_group_arn = aws_lb_target_group.visualiser.arn
    container_name   = "visualiser-container"
    container_port   = 8080
  }]
  tags                   = local.tags
}

module "ecs_service_worker" {
  for_each = local.ecs_worker_services
  source   = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=v6.0.2"

  name                  = "${local.application_name_short}-${local.environment}-${each.key}"
  cluster_arn           = module.ecs-cluster.ecs_cluster_arn
  container_definitions = module.container_definition_worker[each.key].json_encoded_list
  task_cpu              = "512"
  task_memory           = "1024"
  task_role_arn         = aws_iam_role.task.arn
  task_exec_role_arn    = aws_iam_role.execution.arn
  service_role_arn      = aws_iam_role.execution.arn
  security_groups       = [aws_security_group.ecs.id]
  subnets               = data.aws_subnets.shared-private.ids
  enable_execute_command = true
  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }
  efs_volumes            = contains(local.ecs_efs_services, each.key) ? local.ecs_efs_volume : []
  service_load_balancers = []
  tags                   = local.tags
}
