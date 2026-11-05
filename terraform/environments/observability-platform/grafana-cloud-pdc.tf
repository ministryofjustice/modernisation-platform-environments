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
  count = local.grafana_cloud_pdc.en
