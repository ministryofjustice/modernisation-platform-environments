locals {
  forge_name                = "forge-journey-lab"
  forge_ecr_repository_name = "${local.application_name}-${local.forge_name}"
  # Per-environment hostname comes from application_variables.json (see
  # local.application_data in platform_locals.tf) so dev and prod stay distinct.
  forge_hostname            = local.application_data.accounts[local.environment].forge_hostname
  forge_container_image_tag = "latest"
  forge_container_port      = 3000
  forge_task_cpu            = 1024
  forge_task_memory         = 2048
  forge_desired_count       = 1
}

resource "aws_ecr_repository" "forge" {
  # checkov:skip=CKV_AWS_51:MUTABLE supports a convenience latest tag alongside immutable commit SHA tags.
  # checkov:skip=CKV_AWS_136:Single-account prototype images use AWS-managed ECR encryption.
  name                 = local.forge_ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.tags
}

resource "aws_ecr_lifecycle_policy" "forge" {
  repository = aws_ecr_repository.forge.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the latest 30 tagged images"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*"]
          countType      = "imageCountMoreThan"
          countNumber    = 30
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "random_password" "forge_session_secret" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "forge_session_secret" {
  # checkov:skip=CKV2_AWS_57:Rotation is coordinated with an ECS restart to avoid invalidating active sessions mid-request.
  # checkov:skip=CKV_AWS_149:AWS-managed Secrets Manager encryption is proportionate for this prototype.
  name                    = "${local.forge_ecr_repository_name}/session-secret"
  description             = "Express session signing secret for Forge Journey Lab"
  recovery_window_in_days = 7
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "forge_session_secret" {
  secret_id     = aws_secretsmanager_secret.forge_session_secret.id
  secret_string = random_password.forge_session_secret.result

  lifecycle {
    ignore_changes = [secret_string]
  }
}

locals {
  forge_entra_secrets = {
    tenant_id = {
      environment_name = "ENTRA_TENANT_ID"
      description      = "Microsoft Entra tenant ID for Forge Journey Lab"
    }
    client_id = {
      environment_name = "ENTRA_CLIENT_ID"
      description      = "Microsoft Entra application client ID for Forge Journey Lab"
    }
    client_secret = {
      environment_name = "ENTRA_CLIENT_SECRET"
      description      = "Microsoft Entra application client secret for Forge Journey Lab"
    }
  }
}

resource "aws_secretsmanager_secret" "forge_entra" {
  for_each = local.forge_entra_secrets

  # checkov:skip=CKV2_AWS_57:Values are managed and rotated from the externally owned Entra application.
  # checkov:skip=CKV_AWS_149:AWS-managed Secrets Manager encryption is proportionate for this prototype.
  name                    = "${local.forge_ecr_repository_name}/entra-${replace(each.key, "_", "-")}"
  description             = each.value.description
  recovery_window_in_days = 7
  tags                    = local.tags
}

resource "aws_iam_role" "forge_ecs_task_execution" {
  name               = "${local.forge_name}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "forge_ecs_task_execution" {
  role       = aws_iam_role.forge_ecs_task_execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "forge_ecs_task_execution_secrets" {
  statement {
    sid     = "ReadForgeSecrets"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = concat(
      [aws_secretsmanager_secret.forge_session_secret.arn],
      [for secret in aws_secretsmanager_secret.forge_entra : secret.arn]
    )
  }
}

resource "aws_iam_role_policy" "forge_ecs_task_execution_secrets" {
  name   = "read-forge-secrets"
  role   = aws_iam_role.forge_ecs_task_execution.id
  policy = data.aws_iam_policy_document.forge_ecs_task_execution_secrets.json
}

resource "aws_iam_role" "forge_ecs_task" {
  name               = "${local.forge_name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "forge_ecs_task_bedrock" {
  role       = aws_iam_role.forge_ecs_task.name
  policy_arn = aws_iam_policy.bedrock_runtime.arn
}

resource "aws_efs_access_point" "forge" {
  file_system_id = aws_efs_file_system.plans.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/forge-journey-lab"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0770"
    }
  }

  tags = merge(local.tags, { Name = "${local.forge_name}-data-ap" })
}

data "aws_iam_policy_document" "forge_ecs_task_efs" {
  statement {
    sid    = "AllowMountAndReadWriteOnForgeAccessPoint"
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]
    resources = [aws_efs_file_system.plans.arn]
    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values   = [aws_efs_access_point.forge.arn]
    }
  }
}

resource "aws_iam_policy" "forge_ecs_task_efs" {
  name        = "${local.forge_name}-ecs-task-efs"
  description = "Allow Forge Journey Lab to mount its dedicated EFS access point"
  policy      = data.aws_iam_policy_document.forge_ecs_task_efs.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "forge_ecs_task_efs" {
  role       = aws_iam_role.forge_ecs_task.name
  policy_arn = aws_iam_policy.forge_ecs_task_efs.arn
}

# Grant Forge's task role PutObject on the artefact bucket when configured.
# The bucket itself is created out-of-band (see var.forge_package_s3_bucket);
# this policy is gated on the variable being set so turning the integration
# off cleanly removes the IAM.
locals {
  forge_package_s3_enabled = var.forge_package_s3_bucket != ""
}

data "aws_iam_policy_document" "forge_ecs_task_package_s3" {
  count = local.forge_package_s3_enabled ? 1 : 0

  statement {
    sid       = "WriteForgePackages"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.forge_package_s3_bucket}/${var.forge_package_s3_prefix}*"]
  }

  # SSE-KMS buckets require GenerateDataKey + Decrypt on the KMS key S3 uses
  # to encrypt the object. Scoped via kms:ViaService so this grant only applies
  # when S3 is the caller, matching AWS's recommended SSE-KMS pattern.
  statement {
    sid       = "UseS3KmsForPackaging"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "forge_ecs_task_package_s3" {
  count       = local.forge_package_s3_enabled ? 1 : 0
  name        = "${local.forge_name}-ecs-task-package-s3"
  description = "Allow Forge Journey Lab to write packaged build artefacts to the S3 bucket referenced by var.forge_package_s3_bucket."
  policy      = data.aws_iam_policy_document.forge_ecs_task_package_s3[0].json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "forge_ecs_task_package_s3" {
  count      = local.forge_package_s3_enabled ? 1 : 0
  role       = aws_iam_role.forge_ecs_task.name
  policy_arn = aws_iam_policy.forge_ecs_task_package_s3[0].arn
}

resource "aws_security_group" "forge_ecs_service" {
  name        = "${local.forge_name}-ecs"
  description = "Controls access to the Forge Journey Lab ECS service"
  vpc_id      = data.aws_vpc.shared.id
  tags        = merge(local.tags, { Name = "${local.forge_name}-ecs" })
}

resource "aws_vpc_security_group_ingress_rule" "forge_ecs_from_alb" {
  security_group_id            = aws_security_group.forge_ecs_service.id
  description                  = "Forge application traffic from the ALB"
  from_port                    = local.forge_container_port
  to_port                      = local.forge_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_forge_ecs" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward traffic from the ALB to Forge Journey Lab"
  from_port                    = local.forge_container_port
  to_port                      = local.forge_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.forge_ecs_service.id
}

resource "aws_vpc_security_group_egress_rule" "forge_ecs_https" {
  security_group_id = aws_security_group.forge_ecs_service.id
  description       = "HTTPS egress for Entra and AWS APIs"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "forge_ecs_to_efs" {
  security_group_id            = aws_security_group.forge_ecs_service.id
  description                  = "NFS to the Forge data access point"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.efs_plans.id
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_forge_ecs" {
  security_group_id            = aws_security_group.efs_plans.id
  description                  = "NFS from the Forge Journey Lab ECS service"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.forge_ecs_service.id
}

resource "aws_lb_target_group" "forge" {
  # checkov:skip=CKV_AWS_378:TLS terminates at the HTTPS ALB listener. The
  # target uses private subnets and only accepts traffic from the ALB security
  # group, matching the existing builder service's target-group architecture.
  name                 = local.forge_name
  port                 = local.forge_container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = data.aws_vpc.shared.id
  deregistration_delay = 30
  tags                 = local.tags

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/healthz"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "forge" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10
  tags         = local.tags

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.forge.arn
  }

  condition {
    host_header {
      values = [local.forge_hostname]
    }
  }
}

# Forge's Route53 record now lives in route53.tf, alongside the UI's --
# both are aliases to the same ALB, split by host-header listener rule.

resource "aws_cloudwatch_log_group" "forge" {
  # checkov:skip=CKV_AWS_158:Prototype logs use the AWS-managed CloudWatch Logs key.
  # checkov:skip=CKV_AWS_338:Thirty-day retention matches the existing prototype service.
  name              = "/ecs/${local.forge_name}"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_ecs_task_definition" "forge" {
  family                   = local.forge_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = local.forge_task_cpu
  memory                   = local.forge_task_memory
  execution_role_arn       = aws_iam_role.forge_ecs_task_execution.arn
  task_role_arn            = aws_iam_role.forge_ecs_task.arn
  tags                     = local.tags

  container_definitions = jsonencode([
    {
      name                   = "forge"
      image                  = "${aws_ecr_repository.forge.repository_url}:${local.forge_container_image_tag}"
      essential              = true
      readonlyRootFilesystem = true
      user                   = "1000:1000"

      portMappings = [{
        containerPort = local.forge_container_port
        hostPort      = local.forge_container_port
        protocol      = "tcp"
      }]

      environment = [
        { name = "AWS_REGION", value = data.aws_region.current.region },
        { name = "CHROMIUM_SANDBOX_ENABLED", value = "false" },
        { name = "DATA_DIR", value = "/data" },
        { name = "DESIGN_REVIEW_ENABLED", value = "true" },
        { name = "DESIGN_REVIEW_MAX_CORRECTIONS", value = "3" },
        { name = "ENTRA_AUTH_ENABLED", value = "true" },
        { name = "ENTRA_POST_LOGOUT_REDIRECT_URI", value = "https://${local.forge_hostname}/" },
        { name = "ENTRA_REDIRECT_URI", value = "https://${local.forge_hostname}/auth/callback" },
        { name = "FORGE_PACKAGE_S3_BUCKET", value = var.forge_package_s3_bucket },
        { name = "FORGE_PACKAGE_S3_PREFIX", value = var.forge_package_s3_prefix },
        { name = "FORGE_PACKAGE_S3_REGION", value = data.aws_region.current.region },
        { name = "LLM_MODEL", value = var.bedrock_model_id },
        { name = "LLM_PROVIDER", value = "bedrock" },
        { name = "NODE_ENV", value = "production" },
        { name = "PLAYWRIGHT_BROWSERS_PATH", value = "/ms-playwright" },
        { name = "PORT", value = tostring(local.forge_container_port) },
        { name = "SESSION_COOKIE_SECURE", value = "true" },
        { name = "TMPDIR", value = "/data" },
        { name = "TRUST_PROXY_HOPS", value = "1" },
      ]

      secrets = concat(
        [{ name = "SESSION_SECRET", valueFrom = aws_secretsmanager_secret.forge_session_secret.arn }],
        [for key, secret in aws_secretsmanager_secret.forge_entra : {
          name      = local.forge_entra_secrets[key].environment_name
          valueFrom = secret.arn
        }]
      )

      mountPoints = [{
        sourceVolume  = "data"
        containerPath = "/data"
        readOnly      = false
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.forge.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "forge"
          mode                  = "blocking"
        }
      }
    }
  ])

  volume {
    name = "data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.plans.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.forge.id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "forge" {
  name                              = local.forge_name
  cluster                           = aws_ecs_cluster.app.id
  task_definition                   = aws_ecs_task_definition.forge.arn
  desired_count                     = local.forge_desired_count
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 120
  enable_execute_command            = false
  tags                              = local.tags

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.forge_ecs_service.id]
    subnets          = local.private_subnet_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.forge.arn
    container_name   = "forge"
    container_port   = local.forge_container_port
  }

  depends_on = [
    aws_lb_listener_rule.forge,
    aws_efs_mount_target.plans,
  ]

  # CI/CD publishes new task-definition revisions out-of-band and points
  # the service at them via `aws ecs update-service`. Without this,
  # terraform would drag the service back to the last revision it tracks.
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

output "forge_ecr_repository_url" {
  description = "ECR repository URL for the Forge Journey Lab image."
  value       = aws_ecr_repository.forge.repository_url
}

output "forge_url" {
  description = "HTTPS URL for Forge Journey Lab."
  value       = "https://${local.forge_hostname}"
}

output "forge_entra_secret_arns" {
  description = "Secrets Manager ARNs to populate with the Forge Entra application values."
  value       = { for key, secret in aws_secretsmanager_secret.forge_entra : key => secret.arn }
}
