resource "aws_cloudwatch_log_group" "app" {
  # checkov:skip=CKV_AWS_158:Encrypted at rest with the AWS-managed CloudWatch
  # Logs KMS key. A customer-managed CMK adds cost + key rotation ops
  # disproportionate to prototype ECS task logs (no PII / secrets emitted).
  # checkov:skip=CKV_AWS_338:30-day retention is deliberate for a prototype;
  # logs are for short-term operational debugging, not long-term forensics.
  name              = "/ecs/${local.application_name}-ui"
  retention_in_days = 30
  tags              = local.tags
}

locals {
  # UI images are built and pushed centrally to the shared-services account;
  # this component only ever reads a tag, it never owns the repository. The
  # shared-services ECR repository policy must allow pull access from each
  # member account's ecs_task_execution role (managed outside this module).
  ui_ecr_repository_url = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/modernisation-platform-ai-builder-core"
}

resource "aws_ecs_cluster" "app" {
  name = "${local.application_name}-ui"
  tags = local.tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.application_name}-ui"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  tags                     = local.tags

  container_definitions = jsonencode([
    {
      name                   = "ui"
      image                  = "${local.ui_ecr_repository_url}:${var.container_image_tag}"
      essential              = true
      readonlyRootFilesystem = true

      # Override the Dockerfile's ``USER app`` (uid 1000). On Fargate, empty
      # ``volume`` scratch mounts (see ``tmp`` below) come up as root:root 0755
      # and are not writable by uid 1000, which crashes Python's ``tempfile``
      # on import. Running as root is acceptable defence-in-depth here because
      # the root filesystem is read-only (RRF above), the only writable paths
      # are the scratch ``/tmp`` and the EFS access point at ``/data/plans``,
      # and the container sits behind WAF + OIDC + private subnets.
      user = "0:0"

      portMappings = [
        {
          containerPort = var.app_container_port
          hostPort      = var.app_container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "AWS_REGION"
          value = data.aws_region.current.region
        },
        {
          name  = "MPAPB_PLANS_DIR"
          value = "/data/plans"
        },
        {
          name  = "BEDROCK_REGION"
          value = data.aws_region.current.region
        },
        {
          name  = "BEDROCK_MODEL_ID"
          value = var.bedrock_model_id
        },
        # GitHub App -- non-sensitive values (installation id + pem are in
        # the ``secrets`` block below).
        {
          name  = "GITHUB_APP_ID"
          value = var.github_app_id
        },
        {
          name  = "GITHUB_OWNER"
          value = var.github_owner
        },
        {
          name  = "GITHUB_REPO"
          value = var.github_repo
        },
        {
          name  = "GITHUB_EVENT_TYPE"
          value = var.github_event_type
        },
        {
          name  = "GITHUB_INTAKE_WORKFLOW_FILE"
          value = var.github_intake_workflow_file
        },
        # Reviewer dashboard ("/review"): only members of this team can
        # verify their GH username and see the queue. Requires the
        # GitHub App to have Organization -> Members: Read-only granted
        # (see var.reviewer_github_team docstring). Empty disables the
        # team-based path entirely.
        {
          name  = "MPAPB_REVIEWER_GITHUB_TEAM"
          value = var.reviewer_github_team
        },
        # Break-glass allow-list of ``user_id`` values (from /whoami)
        # that bypass the team check. Prefer the team-based path.
        {
          name  = "MPAPB_REVIEWER_USER_IDS"
          value = var.reviewer_user_ids
        },
        # Operator override for the ``email_id`` input on the Deployment
        # workflow dispatch. Empty (default) sends the empty string --
        # matches the caller-agnostic behaviour of dispatch_deployment_
        # workflow. Set (e.g. via TF_VAR_deployment_email_override) while
        # the intake payload does not yet carry a real requester email
        # and Sukesh's Deployment workflow needs a known-good address
        # for its email-notification step.
        {
          name  = "MPAPB_DEPLOYMENT_EMAIL_OVERRIDE"
          value = var.deployment_email_override
        },
        # Emit stdout logs as one-line JSON so CloudWatch Logs Insights can
        # parse fields (event, chat_id, etc.) natively. See ui/app/logging.py.
        {
          name  = "MPAPB_LOG_FORMAT"
          value = "json"
        },
        # Trust the ALB's X-Amzn-Oidc-Identity header only when the listener
        # is actually running the authenticate-oidc action; otherwise the
        # header can be spoofed by anything with network reach to the task.
        # See ui/app/auth.py.
        {
          name  = "MPAPB_TRUST_ALB_OIDC"
          value = local.oidc_wired ? "true" : "false"
        },
        {
          name  = "MPAPB_FORGE_URL"
          value = "https://${local.forge_hostname}"
        },
        # In-app Entra OIDC feature flag. When true (see local.in_app_oidc_
        # enabled) the app runs its own login handshake and the ALB
        # forwards plainly. The tenant / client id / client secret come
        # from Secrets Manager via the ``secrets`` block below; group IDs
        # are non-sensitive tfvars.
        {
          name  = "MPAPB_ENTRA_ENABLED"
          value = local.in_app_oidc_enabled ? "true" : "false"
        },
        {
          name  = "MPAPB_ENTRA_REDIRECT_URI"
          value = local.in_app_oidc_enabled ? "https://${local.builder_hostname}/auth/callback" : ""
        },
        {
          name  = "MPAPB_ENTRA_ADMIN_GROUP_ID"
          value = var.entra_admin_group_id
        },
        {
          name  = "MPAPB_ENTRA_REVIEWER_GROUP_ID"
          value = var.entra_reviewer_group_id
        },
      ]

      # Sensitive values pulled from Secrets Manager at task-start by the
      # execution role. Base secrets live in this account (see secrets.tf).
      # The GitHub App installation id + PEM are created empty by
      # Terraform and populated manually via the AWS console/CLI after
      # apply; the task will fail to start until they hold values.
      #
      # Entra tenant / client id / client secret are appended only when
      # in-app OIDC is enabled -- otherwise the task doesn't need them and
      # the ALB reads them itself for the authenticate-oidc action.
      secrets = concat(
        [
          {
            name      = "MPAPB_SECRET_KEY"
            valueFrom = aws_secretsmanager_secret.mpapb_secret_key.arn
          },
          {
            name      = "GITHUB_APP_INSTALLATION_ID"
            valueFrom = aws_secretsmanager_secret.github_app_installation_id.arn
          },
          {
            name      = "GITHUB_APP_PRIVATE_KEY"
            valueFrom = aws_secretsmanager_secret.github_app_private_key.arn
          },
        ],
        local.in_app_oidc_enabled ? [
          {
            name      = "MPAPB_ENTRA_TENANT_ID"
            valueFrom = aws_secretsmanager_secret.entra_oidc_tenant_id[0].arn
          },
          {
            name      = "MPAPB_ENTRA_CLIENT_ID"
            valueFrom = aws_secretsmanager_secret.entra_oidc_client_id[0].arn
          },
          {
            name      = "MPAPB_ENTRA_CLIENT_SECRET"
            valueFrom = aws_secretsmanager_secret.entra_oidc_client_secret[0].arn
          },
        ] : []
      )

      mountPoints = [
        {
          sourceVolume  = "tmp"
          containerPath = "/tmp"
          readOnly      = false
        },
        {
          sourceVolume  = "plans"
          containerPath = "/data/plans"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "ui"
          mode                  = "blocking"
        }
      }
    }
  ])

  volume {
    name = "tmp"
  }

  volume {
    name = "plans"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.plans.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.plans.id
        # Use the task role's IAM permissions to authenticate to EFS instead
        # of relying on POSIX perms alone.
        iam = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "app" {
  name                              = "${local.application_name}-ui"
  cluster                           = aws_ecs_cluster.app.id
  task_definition                   = aws_ecs_task_definition.app.arn
  desired_count                     = var.app_desired_count
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 60
  enable_execute_command            = false
  tags                              = local.tags

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_service.id]
    subnets          = local.private_subnet_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "ui"
    container_port   = var.app_container_port
  }

  depends_on = [
    aws_lb_listener.https
  ]

  # Task-def revisions get rolled forward by CI/CD (or by the emergency
  # ``aws ecs update-service`` we used to recover from the middleware
  # bug); leaving this attribute unmanaged stops terraform dragging the
  # service back to an older revision.
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
