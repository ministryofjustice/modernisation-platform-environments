# Private Data Source Connect (PDC) over AWS PrivateLink.
# Each environment's stack gets one PDC network for the platforms-<environment> VPC.
# Agents run on ECS Fargate in the VPC's general private subnets and reach Grafana Cloud
# through interface endpoints that the Modernisation Platform creates in core-vpc.
# The pilot pulls the agent image from Docker Hub, pinned by digest. The tenant module
# will move it to a core-shared-services ECR repository.

locals {
  grafana_cloud_pdc = {
    development = {
      enabled     = true
      agent_count = 2
      # host:port pairs the agent may forward queries to. Empty allows any destination
      # that the agent security group permits (the VPC CIDR only).
      permit_remote_open = []
    }
    production = {
      enabled            = false
      agent_count        = 2
      permit_remote_open = []
    }
  }[local.environment]

  grafana_cloud_pdc_name = "${var.networking[0].business-unit}-${local.environment}"

  # grafana/pdc-agent 0.0.67. Tags on Docker Hub are mutable, so the task pins the image index digest.
  grafana_cloud_pdc_agent_image = "docker.io/grafana/pdc-agent@sha256:e17e65368ca5d8267e8996030869c5cf1b6929e0344e08e90eef6e1179172601"
}

resource "grafana_cloud_private_data_source_connect_network" "platforms" {
  count    = local.grafana_cloud_pdc.enabled ? 1 : 0
  provider = grafana.cloud

  name             = local.grafana_cloud_pdc_name
  display_name     = "Modernisation Platform ${local.grafana_cloud_pdc_name} VPC"
  region           = grafana_cloud_stack.observability_platform.region_slug
  stack_identifier = grafana_cloud_stack.observability_platform.id
}

resource "grafana_cloud_private_data_source_connect_network_token" "platforms" {
  count    = local.grafana_cloud_pdc.enabled ? 1 : 0
  provider = grafana.cloud

  name           = "${local.grafana_cloud_pdc_name}-agent"
  display_name   = "${local.grafana_cloud_pdc_name} ECS agents"
  pdc_network_id = grafana_cloud_private_data_source_connect_network.platforms[0].pdc_network_id
  region         = grafana_cloud_private_data_source_connect_network.platforms[0].region
}

resource "aws_secretsmanager_secret_version" "grafana_cloud_pdc_token" {
  count = local.grafana_cloud_pdc.enabled ? 1 : 0

  secret_id     = aws_secretsmanager_secret.grafana_cloud_pdc_token[0].id
  secret_string = grafana_cloud_private_data_source_connect_network_token.platforms[0].token
}

# ---------------------------------------------------------------------------------------------------------------------
# PDC agents
# ---------------------------------------------------------------------------------------------------------------------

#tfsec:ignore:aws-cloudwatch-log-group-customer-key CMK not required currently
resource "aws_cloudwatch_log_group" "grafana_pdc_agent" {
  #checkov:skip=CKV_AWS_158:CMK not required currently
  count = local.grafana_cloud_pdc.enabled ? 1 : 0

  name              = "/ecs/grafana-pdc-agent"
  retention_in_days = 400

  tags = local.tags
}

resource "aws_ecs_cluster" "grafana_pdc_agent" {
  count = local.grafana_cloud_pdc.enabled ? 1 : 0

  name = "grafana-pdc-agent"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.tags
}

data "aws_iam_policy_document" "grafana_pdc_agent_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "grafana_pdc_agent_execution" {
  count = local.grafana_cloud_pdc.enabled ? 1 : 0

  statement {
    sid       = "ReadPdcToken"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.grafana_cloud_pdc_token[0].arn]
  }
}

resource "aws_iam_role" "grafana_pdc_agent_execution" {
  count = local.grafana_cloud_pdc.enabled ? 1 : 0

  name               = "grafana-pdc-agent-execution"
  assume_role_policy = data.aws_iam_policy_document.grafana_pdc_agent_assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "grafana_pdc_agent_execution" {
  count = local.grafana_cloud_pdc.enabled ? 1 : 0

  role       = aws_iam_role.grafana_pdc_agent_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "grafana_pdc_agent_execution" {
  count = local.grafana_cloud_pdc.enabled ? 1 : 0

  name   = "read-pdc-token"
  role   = aws_iam_role.grafana_pdc_agent_execution[0].id
  policy = data.aws_iam_policy_document.grafana_pdc_agent_execution[0].json
}

resource "aws_security_group" "grafana_pdc_agent" {
  count = local.grafana_cloud_pdc.enabled ? 1 : 0

  name        = "grafana-pdc-agent"
  description = "Grafana PDC agent: outbound to PDC endpoints and private data sources"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, { Name = "grafana-pdc-agent" })
}

resource "aws_vpc_security_group_egress_rule" "grafana_pdc_agent_vpc" {
  count = local.grafana_cloud_pdc.enabled ? 1 : 0

  security_group_id = aws_security_group.grafana_pdc_agent[0].id
  description       = "PDC endpoints (443, 22) and data sources inside the VPC"
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
}

resource "aws_vpc_security_group_egress_rule" "grafana_pdc_agent_https" {
  #checkov:skip=CKV_AWS_382:Docker Hub image pulls go through MP's network firewall; Logs and Secrets Manager use central VPC endpoints
  count = local.grafana_cloud_pdc.enabled ? 1 : 0

  security_group_id = aws_security_group.grafana_pdc_agent[0].id
  description       = "Docker Hub, CloudWatch Logs and Secrets Manager over HTTPS"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_ecs_task_definition" "grafana_pdc_agent" {
  #checkov:skip=CKV_AWS_336:Agent writes its SSH key and certificate to the home directory
  count = local.grafana_cloud_pdc.enabled ? 1 : 0

  family                   = "grafana-pdc-agent"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.grafana_pdc_agent_execution[0].arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "pdc-agent"
      image     = local.grafana_cloud_pdc_agent_image
      essential = true
      command = concat(
        [
          "-api-fqdn", grafana_cloud_stack.observability_platform.pdc_api_private_connectivity_info_private_dns,
          "-gateway-fqdn", grafana_cloud_stack.observability_platform.pdc_gateway_private_connectivity_info_private_dns,
          "-gcloud-hosted-grafana-id", grafana_cloud_stack.observability_platform.id,
        ],
        length(local.grafana_cloud_pdc.permit_remote_open) > 0 ? [
          "-ssh-flag=-o PermitRemoteOpen=${join(" ", local.grafana_cloud_pdc.permit_remote_open)}"
        ] : []
      )
      secrets = [
        {
          name      = "GCLOUD_PDC_SIGNING_TOKEN"
          valueFrom = aws_secretsmanager_secret.grafana_cloud_pdc_token[0].arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.grafana_pdc_agent[0].name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "pdc-agent"
        }
      }
    }
  ])

  tags = local.tags
}

resource "aws_ecs_service" "grafana_pdc_agent" {
  count = local.grafana_cloud_pdc.enabled ? 1 : 0

  name                               = "grafana-pdc-agent"
  cluster                            = aws_ecs_cluster.grafana_pdc_agent[0].id
  task_definition                    = aws_ecs_task_definition.grafana_pdc_agent[0].arn
  launch_type                        = "FARGATE"
  desired_count                      = local.grafana_cloud_pdc.agent_count
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = data.aws_subnets.shared-private.ids
    security_groups  = [aws_security_group.grafana_pdc_agent[0].id]
    assign_public_ip = false
  }

  tags = local.tags
}

output "grafana_cloud_pdc_network" {
  description = "PDC network for this environment's stack. Use the ID as secureSocksProxyUsername on data sources."
  value = local.grafana_cloud_pdc.enabled ? {
    name           = grafana_cloud_private_data_source_connect_network.platforms[0].name
    pdc_network_id = grafana_cloud_private_data_source_connect_network.platforms[0].pdc_network_id
    agent_sg_id    = aws_security_group.grafana_pdc_agent[0].id
  } : null
}
