data "aws_availability_zones" "available" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

# Shared VPC and Subnets
data "aws_vpc" "shared" {
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}"
  }
}

data "aws_ssoadmin_instances" "main" {
  provider = aws.sso-readonly
}

data "aws_ec2_transit_gateway" "moj_tgw" {
  id = "tgw-026162f1ba39ce704"
}

data "aws_iam_roles" "eks_sso_access_role" {
  name_regex  = "AWSReservedSSO_${local.environment_configuration.eks_sso_access_role}_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "data_engineering_sso_role" {
  name_regex  = "AWSReservedSSO_modernisation-platform-data-eng_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "platform_engineer_admin_sso_role" {
  name_regex  = "AWSReservedSSO_platform-engineer-admin_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "http" "prometheus_operator_crds" {
  for_each = {
    alertmanagerconfigs = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus_operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml"
    alertmanagers       = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus_operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml"
    podmonitors         = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus_operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml"
    probes              = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus_operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml"
    prometheus_agents   = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus_operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_prometheusagents.yaml"
    prometheuses        = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus_operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml"
    prometheusrules     = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus_operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml"
    scrapeconfigs       = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus_operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_scrapeconfigs.yaml"
    servicemonitors     = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus_operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml"
    thanosrulers        = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus_operator_crd_version}/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml"
  }

  url = each.value
}

data "aws_secretsmanager_secret_version" "actions_runners_token_apc_self_hosted_runners_github_app" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  secret_id = data.aws_secretsmanager_secret.actions_runners_token_apc_self_hosted_runners_github_app[0].id
}

data "aws_secretsmanager_secret" "actions_runners_token_apc_self_hosted_runners_github_app" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  name = "actions-runners/app/apc-self-hosted-runners"
}

# Application Load Balancer
data "aws_lb" "mwaa_alb" {
  name = "mwaa"
}

# KMS
data "aws_kms_key" "mwaa_kms" {
  key_id = "alias/mwaa/default"
}

data "aws_s3_bucket" "mwaa_bucket" {
  bucket = "mojap-compute-${local.environment}-mwaa"
}

data "aws_route53_resolver_query_log_config" "core_logging_s3" {
  filter {
    name   = "Name"
    values = ["core-logging-rlq-s3"]
  }
}

# move cluster to component

data "aws_kms_alias" "eks_logs" {
  name = "alias/eks/cluster-logs"
}

data "aws_kms_key" "eks_logs" {
  key_id = data.aws_kms_alias.eks_logs.target_key_id
}

data "aws_eks_cluster" "eks" {
  name = local.eks_cluster_name
}

data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

data "kubernetes_namespace" "aws_observability" {
  metadata {
    name = "aws-observability"
  }
}

data "kubernetes_namespace" "mwaa" {
  metadata {
    name = "mwaa"
  }
}

data "kubernetes_service_account" "mwaa_external_secrets" {
  metadata {
    name      = "external-secrets-analytical-platform-data-production"
    namespace = data.kubernetes_namespace.mwaa.metadata[0].name
  }
}

data "kubernetes_service_account" "mwaa_external_secrets_analytical_platform_data_production_name" {
  metadata {
    name = "external-secrets-analytical-platform-data-production"
  }
}

data "aws_route53_zone" "network_services" {
  name         = "compute.${local.environment}.analytical-platform.service.justice.gov.uk"
  private_zone = false
}
