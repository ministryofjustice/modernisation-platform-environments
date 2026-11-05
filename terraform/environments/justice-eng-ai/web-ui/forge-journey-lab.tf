locals {
  forge_internal = var.forge_deployment_mode == "internal"

  # Single-URL switches -- see application_variables.json's per-account
  # forge_* keys. try() falls back to the pre-single-URL behaviour (public
  # endpoint + embedded Entra login, same as before these keys existed) for
  # any account that doesn't set them.
  forge_single_url_enabled = local.forge_internal && try(local.application_data.accounts[local.environment].forge_single_url_enabled, false)
  forge_base_path          = try(local.application_data.accounts[local.environment].forge_base_path, "/")
  forge_upstream_port      = try(local.application_data.accounts[local.environment].forge_upstream_port, 3000)
  # Whether Forge keeps a public ALB route/Route53 record/cert SAN. See
  # load-balancer.tf's listener rule, route53.tf's record + cert SAN.
  forge_public_endpoint_enabled = local.forge_internal && try(local.application_data.accounts[local.environment].forge_public_endpoint_enabled, true)
  # Whether Forge runs its own Entra login (the pre-single-URL model). False
  # once Builder's proxy forwards its own verified identity instead.
  forge_embedded_entra_enabled = try(local.application_data.accounts[local.environment].forge_embedded_entra_enabled, true)

  # What the UI's forge.html iframe loads in the browser. Empty in
  # single-URL mode (Builder's /forge/ embeds same-origin /forge-app/
  # instead, proxied server-side -- see forge_upstream_url below) or when
  # forge_deployment_mode = "disabled".
  forge_url = (
    local.forge_single_url_enabled ? "" :
    var.forge_deployment_mode == "internal" ? "https://${local.forge_hostname}" :
    var.forge_deployment_mode == "external" ? var.external_forge_url :
    ""
  )
  # Private service-discovery address Builder proxies to -- see
  # service-discovery.tf. try() guards the [0] index while single-url mode
  # is off and the namespace doesn't exist.
  forge_upstream_url = local.forge_single_url_enabled ? "http://${local.forge_name}.${try(aws_service_discovery_private_dns_namespace.internal[0].name, "")}:${local.forge_upstream_port}" : ""

  forge_name = "forge-journey-lab"
  # Secrets Manager path prefix only -- the image itself lives in the shared
  # ECR repository used by the UI (ecs.tf), built/pushed centrally.
  forge_secret_path_prefix = "${local.application_name}-${local.forge_name}"
  # Per-environment hostname comes from application_variables.json (see
  # local.application_data in platform_locals.tf) so dev and prod stay distinct.
  # Only used for real when forge_public_endpoint_enabled -- see
  # local.forge_url/local.forge_upstream_url above for what Builder actually
  # gets handed.
  forge_hostname           = local.application_data.accounts[local.environment].forge_hostname
  forge_ecr_repository_url = local.ui_ecr_repository_url
  forge_container_port     = local.forge_upstream_port
  forge_task_cpu           = 1024
  forge_task_memory        = 2048
  forge_desired_count      = 1
}

resource "random_password" "forge_session_secret" {
  count = local.forge_internal ? 1 : 0

  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "forge_session_secret" {
  count = local.forge_internal ? 1 : 0

  # checkov:skip=CKV2_AWS_57:Rotation is coordinated with an ECS restart to avoid invalidating active sessions mid-request.
  # checkov:skip=CKV_AWS_149:AWS-managed Secrets Manager encryption is proportionate for this prototype.
  name                    = "${local.forge_secret_path_prefix}/session-secret"
  description             = "Express session signing secret for Forge Journey Lab"
  recovery_window_in_days = 7
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "forge_session_secret" {
  count = local.forge_internal ? 1 : 0

  secret_id     = aws_secretsmanager_secret.forge_session_secret[0].id
  secret_string = random_password.forge_session_secret[0].result

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Forge Journey Lab uses the same Entra app registration as the UI, so it
# reads the shared aws_secretsmanager_secret.entra_oidc_* secrets (oidc.tf)
# rather than keeping its own copies. Only relevant while
# forge_embedded_entra_enabled -- see the task def's secrets block below.

# Shared bearer token for Builder's private proxy calls to Forge
# (MPAPB_FORGE_PROXY_TOKEN / FORGE_TRUSTED_PROXY_TOKEN). Auto-generated like
# forge_session_secret above -- both Builder and Forge read this same
# secret ARN, so a single generation point keeps the two sides in sync.
resource "random_password" "forge_proxy_token" {
  count = local.forge_single_url_enabled ? 1 : 0

  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "forge_proxy_token" {
  count = local.forge_single_url_enabled ? 1 : 0

  # checkov:skip=CKV2_AWS_57:Rotation requires coordinated redeploys of both
  # Builder and Forge; manual rotation is acceptable for this prototype.
  # checkov:skip=CKV_AWS_149:AWS-managed Secrets Manager encryption is
  # proportionate for this prototype migration.
  name                    = "${local.forge_secret_path_prefix}/proxy-token"
  description             = "Shared bearer token Builder presents on its private proxy calls to Forge"
  recovery_window_in_days = 7
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "forge_proxy_token" {
  count = local.forge_single_url_enabled ? 1 : 0

  secret_id     = aws_secretsmanager_secret.forge_proxy_token[0].id
  secret_string = random_password.forge_proxy_token[0].result

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_iam_role" "forge_ecs_task_execution" {
  count = local.forge_internal ? 1 : 0

  name               = "${local.forge_name}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "forge_ecs_task_execution" {
  count = local.forge_internal ? 1 : 0

  role       = aws_iam_role.forge_ecs_task_execution[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "forge_ecs_task_execution_secrets" {
  count = local.forge_internal ? 1 : 0

  statement {
    sid     = "ReadForgeSecrets"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.forge_session_secret[0].arn,
    ]
  }

  dynamic "statement" {
    for_each = local.forge_embedded_entra_enabled ? [1] : []
    content {
      sid     = "ReadForgeEntraSecrets"
      effect  = "Allow"
      actions = ["secretsmanager:GetSecretValue"]
      resources = [
        aws_secretsmanager_secret.entra_oidc_tenant_id[0].arn,
        aws_secretsmanager_secret.entra_oidc_client_id[0].arn,
        aws_secretsmanager_secret.entra_oidc_client_secret[0].arn,
      ]
    }
  }

  dynamic "statement" {
    for_each = local.forge_single_url_enabled ? [1] : []
    content {
      sid       = "ReadForgeProxyToken"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [aws_secretsmanager_secret.forge_proxy_token[0].arn]
    }
  }
}

resource "aws_iam_role_policy" "forge_ecs_task_execution_secrets" {
  count = local.forge_internal ? 1 : 0

  name   = "read-forge-secrets"
  role   = aws_iam_role.forge_ecs_task_execution[0].id
  policy = data.aws_iam_policy_document.forge_ecs_task_execution_secrets[0].json
}

resource "aws_iam_role" "forge_ecs_task" {
  count = local.forge_internal ? 1 : 0

  name               = "${local.forge_name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "forge_ecs_task_bedrock" {
  count = local.forge_internal ? 1 : 0

  role       = aws_iam_role.forge_ecs_task[0].name
  policy_arn = aws_iam_policy.bedrock_runtime.arn
}

resource "aws_efs_access_point" "forge" {
  count = local.forge_internal ? 1 : 0

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
  count = local.forge_internal ? 1 : 0

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
      values   = [aws_efs_access_point.forge[0].arn]
    }
  }
}

resource "aws_iam_policy" "forge_ecs_task_efs" {
  count = local.forge_internal ? 1 : 0

  name        = "${local.forge_name}-ecs-task-efs"
  description = "Allow Forge Journey Lab to mount its dedicated EFS access point"
  policy      = data.aws_iam_policy_document.forge_ecs_task_efs[0].json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "forge_ecs_task_efs" {
  count = local.forge_internal ? 1 : 0

  role       = aws_iam_role.forge_ecs_task[0].name
  policy_arn = aws_iam_policy.forge_ecs_task_efs[0].arn
}

# Grant Forge's task role PutObject on the artefact bucket. The bucket
# itself is created out-of-band (see local.forge_package_s3_bucket in
# locals.tf, which defaults to the backend-processing root's staging
# bucket); this policy is gated on Forge actually being deployed here, so
# turning that off cleanly removes the IAM.
locals {
  forge_package_s3_enabled = local.forge_internal && local.forge_package_s3_bucket != ""
}

data "aws_iam_policy_document" "forge_ecs_task_package_s3" {
  count = local.forge_package_s3_enabled ? 1 : 0

  statement {
    sid       = "WriteForgePackages"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${local.forge_package_s3_bucket}/${var.forge_package_s3_prefix}*"]
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
  description = "Allow Forge Journey Lab to write packaged build artefacts to the S3 bucket referenced by local.forge_package_s3_bucket."
  policy      = data.aws_iam_policy_document.forge_ecs_task_package_s3[0].json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "forge_ecs_task_package_s3" {
  count      = local.forge_package_s3_enabled ? 1 : 0
  role       = aws_iam_role.forge_ecs_task[0].name
  policy_arn = aws_iam_policy.forge_ecs_task_package_s3[0].arn
}

# Grant Forge's task role write access to the build-details table, which
# packaging records each build in before the S3 upload. The table is owned by
# the backend-processing root (dynamodb.tf there); its name is read from that
# root's outputs, like the staging bucket. Forge only writes to DynamoDB when
# it packages to S3, so this is gated on the same flag.
#   UpdateItem: atomically increments the per-app counter item (SysKey 0).
#   PutItem:    writes the build record (conditional, never overwrites).
# The table uses the AWS-managed DynamoDB key, so no KMS grant is needed.
# try() guards against backend-processing not having been applied with its
# build_details_table_name output yet -- remove once it has been.
locals {
  forge_build_details_table_name = try(data.terraform_remote_state.backend_processing.outputs.build_details_table_name, "")
  forge_build_details_enabled    = local.forge_package_s3_enabled && local.forge_build_details_table_name != ""
}

data "aws_iam_policy_document" "forge_ecs_task_build_details" {
  count = local.forge_build_details_enabled ? 1 : 0

  statement {
    sid    = "RecordForgeBuilds"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:dynamodb:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/${local.forge_build_details_table_name}"]
  }

  # Requester status uses a projected Query, never Scan or workflow tokens.
  statement {
    sid       = "ReadForgeRequesterStatus"
    effect    = "Allow"
    actions   = ["dynamodb:Query"]
    resources = ["arn:${data.aws_partition.current.partition}:dynamodb:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/${local.forge_build_details_table_name}"]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "dynamodb:Attributes"
      values   = ["AppID", "SysKey", "BuildID", "UserName", "JobStage", "JobStatus", "Date", "ReviewReason", "Reasons"]
    }
    condition {
      test     = "Null"
      variable = "dynamodb:Attributes"
      values   = ["false"]
    }
    condition {
      test     = "StringEquals"
      variable = "dynamodb:Select"
      values   = ["SPECIFIC_ATTRIBUTES"]
    }
  }
}

resource "aws_iam_policy" "forge_ecs_task_build_details" {
  count       = local.forge_build_details_enabled ? 1 : 0
  name        = "${local.forge_name}-ecs-task-build-details"
  description = "Allow Forge Journey Lab to record packaged builds and read projected requester status."
  policy      = data.aws_iam_policy_document.forge_ecs_task_build_details[0].json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "forge_ecs_task_build_details" {
  count      = local.forge_build_details_enabled ? 1 : 0
  role       = aws_iam_role.forge_ecs_task[0].name
  policy_arn = aws_iam_policy.forge_ecs_task_build_details[0].arn
}

resource "aws_security_group" "forge_ecs_service" {
  count = local.forge_internal ? 1 : 0

  name        = "${local.forge_name}-ecs"
  description = "Controls access to the Forge Journey Lab ECS service"
  vpc_id      = data.aws_vpc.shared.id
  tags        = merge(local.tags, { Name = "${local.forge_name}-ecs" })
}

resource "aws_vpc_security_group_ingress_rule" "forge_ecs_from_alb" {
  count = local.forge_public_endpoint_enabled ? 1 : 0

  security_group_id            = aws_security_group.forge_ecs_service[0].id
  description                  = "Forge application traffic from the ALB"
  from_port                    = local.forge_container_port
  to_port                      = local.forge_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_forge_ecs" {
  count = local.forge_public_endpoint_enabled ? 1 : 0

  security_group_id            = aws_security_group.alb.id
  description                  = "Forward traffic from the ALB to Forge Journey Lab"
  from_port                    = local.forge_container_port
  to_port                      = local.forge_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.forge_ecs_service[0].id
}

# Direct path for Builder's private proxy (MPAPB_FORGE_UPSTREAM_URL) --
# independent of the public-endpoint rules above, needed whenever
# single-url mode is on regardless of whether the public route still exists.
resource "aws_vpc_security_group_ingress_rule" "forge_ecs_from_builder" {
  count = local.forge_single_url_enabled ? 1 : 0

  security_group_id            = aws_security_group.forge_ecs_service[0].id
  description                  = "Forge proxy traffic from Builder"
  from_port                    = local.forge_container_port
  to_port                      = local.forge_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_service.id
}

resource "aws_vpc_security_group_egress_rule" "builder_to_forge_ecs" {
  count = local.forge_single_url_enabled ? 1 : 0

  security_group_id            = aws_security_group.ecs_service.id
  description                  = "Builder proxy traffic to Forge"
  from_port                    = local.forge_container_port
  to_port                      = local.forge_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.forge_ecs_service[0].id
}

resource "aws_vpc_security_group_egress_rule" "forge_ecs_https" {
  count = local.forge_internal ? 1 : 0

  security_group_id = aws_security_group.forge_ecs_service[0].id
  description       = "HTTPS egress for Entra and AWS APIs"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "forge_ecs_to_efs" {
  count = local.forge_internal ? 1 : 0

  security_group_id            = aws_security_group.forge_ecs_service[0].id
  description                  = "NFS to the Forge data access point"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.efs_plans.id
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_forge_ecs" {
  count = local.forge_internal ? 1 : 0

  security_group_id            = aws_security_group.efs_plans.id
  description                  = "NFS from the Forge Journey Lab ECS service"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.forge_ecs_service[0].id
}

resource "aws_lb_target_group" "forge" {
  count = local.forge_public_endpoint_enabled ? 1 : 0

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
  count = local.forge_public_endpoint_enabled ? 1 : 0

  listener_arn = aws_lb_listener.https.arn
  priority     = 10
  tags         = local.tags

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.forge[0].arn
  }

  condition {
    host_header {
      values = [local.forge_hostname]
    }
  }
}

# Forge's Route53 record now lives in route53.tf, alongside the UI's --
# both are aliases to the same ALB, split by host-header listener rule.
# Only created when forge_public_endpoint_enabled (see route53.tf).

resource "aws_cloudwatch_log_group" "forge" {
  count = local.forge_internal ? 1 : 0

  # checkov:skip=CKV_AWS_158:Prototype logs use the AWS-managed CloudWatch Logs key.
  # checkov:skip=CKV_AWS_338:Thirty-day retention matches the existing prototype service.
  name              = "/ecs/${local.forge_name}"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_ecs_task_definition" "forge" {
  count = local.forge_internal ? 1 : 0

  family                   = local.forge_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = local.forge_task_cpu
  memory                   = local.forge_task_memory
  execution_role_arn       = aws_iam_role.forge_ecs_task_execution[0].arn
  task_role_arn            = aws_iam_role.forge_ecs_task[0].arn
  tags                     = local.tags

  container_definitions = jsonencode([
    {
      name                   = "forge"
      image                  = "${local.forge_ecr_repository_url}:${var.forge_container_image_tag}"
      essential              = true
      readonlyRootFilesystem = true
      user                   = "1000:1000"

      portMappings = [{
        containerPort = local.forge_container_port
        hostPort      = local.forge_container_port
        protocol      = "tcp"
      }]

      environment = concat(
        [
          { name = "AWS_REGION", value = data.aws_region.current.region },
          { name = "CHROMIUM_SANDBOX_ENABLED", value = "false" },
          { name = "DATA_DIR", value = "/data" },
          { name = "DESIGN_REVIEW_ENABLED", value = "true" },
          { name = "DESIGN_REVIEW_MAX_CORRECTIONS", value = "3" },
          # Builder forwards its own verified identity in single-url mode
          # (local.forge_single_url_enabled), so Forge's own Entra login is
          # disabled rather than double-authenticating. RUNTIME_BASE_URL is
          # deliberately never set here -- incompatible with FORGE_BASE_PATH.
          { name = "ENTRA_AUTH_ENABLED", value = local.forge_embedded_entra_enabled ? "true" : "false" },
          { name = "FORGE_BASE_PATH", value = local.forge_base_path },
          { name = "FORGE_PACKAGE_S3_BUCKET", value = local.forge_package_s3_bucket },
          { name = "FORGE_PACKAGE_KEY_VERSION", value = "2" },
          { name = "FORGE_PACKAGE_S3_PREFIX", value = var.forge_package_s3_prefix },
          { name = "FORGE_PACKAGE_S3_REGION", value = data.aws_region.current.region },
          { name = "REVIEW_TABLE_NAME", value = local.build_review_table_name },
          { name = "LLM_MODEL", value = var.bedrock_model_id },
          { name = "LLM_PROVIDER", value = "bedrock" },
          { name = "NODE_ENV", value = "production" },
          { name = "PLAYWRIGHT_BROWSERS_PATH", value = "/ms-playwright" },
          { name = "PORT", value = tostring(local.forge_container_port) },
          { name = "SESSION_COOKIE_SECURE", value = "true" },
          { name = "TMPDIR", value = "/data" },
          { name = "TRUST_PROXY_HOPS", value = "1" },
        ],
        local.forge_embedded_entra_enabled ? [
          { name = "ENTRA_POST_LOGOUT_REDIRECT_URI", value = "https://${local.forge_hostname}/" },
          { name = "ENTRA_REDIRECT_URI", value = "https://${local.forge_hostname}/auth/callback" },
        ] : [],
      )

      secrets = concat(
        [
          { name = "SESSION_SECRET", valueFrom = aws_secretsmanager_secret.forge_session_secret[0].arn },
        ],
        local.forge_embedded_entra_enabled ? [
          { name = "ENTRA_TENANT_ID", valueFrom = aws_secretsmanager_secret.entra_oidc_tenant_id[0].arn },
          { name = "ENTRA_CLIENT_ID", valueFrom = aws_secretsmanager_secret.entra_oidc_client_id[0].arn },
          { name = "ENTRA_CLIENT_SECRET", valueFrom = aws_secretsmanager_secret.entra_oidc_client_secret[0].arn },
        ] : [],
        local.forge_single_url_enabled ? [
          { name = "FORGE_TRUSTED_PROXY_TOKEN", valueFrom = aws_secretsmanager_secret.forge_proxy_token[0].arn },
        ] : [],
      )

      mountPoints = [{
        sourceVolume  = "data"
        containerPath = "/data"
        readOnly      = false
      }]

      # Uses node directly rather than curl/wget, which the image may not have.
      healthCheck = {
        command     = ["CMD-SHELL", "node -e \"require('http').get('http://localhost:${local.forge_container_port}/healthz', (r) => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))\""]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.forge[0].name
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
        access_point_id = aws_efs_access_point.forge[0].id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "forge" {
  count = local.forge_internal ? 1 : 0

  name                              = local.forge_name
  cluster                           = aws_ecs_cluster.app.id
  task_definition                   = aws_ecs_task_definition.forge[0].arn
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
    security_groups  = [aws_security_group.forge_ecs_service[0].id]
    subnets          = local.private_subnet_ids
  }

  # Only registered with the ALB target group while Forge keeps a public
  # route -- in single-url mode Builder reaches Forge via service discovery
  # instead (service_registries below), not the ALB.
  dynamic "load_balancer" {
    for_each = local.forge_public_endpoint_enabled ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.forge[0].arn
      container_name   = "forge"
      container_port   = local.forge_container_port
    }
  }

  # Private DNS record Builder's proxy resolves (service-discovery.tf).
  dynamic "service_registries" {
    for_each = local.forge_single_url_enabled ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.forge[0].arn
    }
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
  description = "Shared-services ECR repository URL the Forge Journey Lab image is pulled from. Empty unless forge_deployment_mode = \"internal\"."
  value       = local.forge_internal ? local.forge_ecr_repository_url : ""
}

output "forge_url" {
  description = "URL the UI embeds for Forge Journey Lab (internal/external), or empty when disabled."
  value       = local.forge_url
}

output "forge_entra_secret_arns" {
  description = "Secrets Manager ARNs to populate with the Entra application values, shared between the UI and Forge Journey Lab. Empty unless forge_deployment_mode = \"internal\" or var.enable_oidc_auth."
  value = {
    tenant_id     = try(aws_secretsmanager_secret.entra_oidc_tenant_id[0].arn, "")
    client_id     = try(aws_secretsmanager_secret.entra_oidc_client_id[0].arn, "")
    client_secret = try(aws_secretsmanager_secret.entra_oidc_client_secret[0].arn, "")
  }
}
