data "aws_availability_zones" "available" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_ssoadmin_instances" "main" {
  provider = aws.sso-readonly
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

data "aws_vpc" "apc_vpc" {
  filter {
    name   = "tag:Name"
    values = [local.our_vpc_name]
  }
}

data "aws_subnet" "intra_subnet_a" {
  vpc_id = data.aws_vpc.apc_vpc.id
  tags = {
    "Name" = "${local.our_vpc_name}-${local.environment}-intra-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "intra_subnet_b" {
  vpc_id = data.aws_vpc.apc_vpc.id
  tags = {
    "Name" = "${local.our_vpc_name}-${local.environment}-intra-${data.aws_region.current.name}b"
  }
}

data "aws_subnet" "intra_subnet_c" {
  vpc_id = data.aws_vpc.apc_vpc.id
  tags = {
    "Name" = "${local.our_vpc_name}-${local.environment}-intra-${data.aws_region.current.name}c"
  }
}

data "aws_subnet" "private_subnet_a" {
  vpc_id = data.aws_vpc.apc_vpc.id
  tags = {
    "Name" = "${local.our_vpc_name}-${local.environment}-private-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "private_subnet_b" {
  vpc_id = data.aws_vpc.apc_vpc.id
  tags = {
    "Name" = "${local.our_vpc_name}-${local.environment}-private-${data.aws_region.current.name}b"
  }
}

data "aws_subnet" "private_subnet_c" {
  vpc_id = data.aws_vpc.apc_vpc.id
  tags = {
    "Name" = "${local.our_vpc_name}-${local.environment}-private-${data.aws_region.current.name}c"
  }
}

data "aws_secretsmanager_secret_version" "actions_runners_token_apc_self_hosted_runners_github_app" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  secret_id = module.actions_runners_token_apc_self_hosted_runners_github_app[0].secret_id
}

data "aws_route53_zone" "apc_route53_zone" {
  name = local.environment_configuration.route53_zone
}

data "aws_kms_key" "common_secrets_manager_kms" {
  key_id = "alias/secretsmanager/common"
}

data "aws_iam_policy" "analytical_platform_lake_formation_share_policy" {
  path_prefix = "analytical-platform-lake-formation-sharing-policy"
}

data "aws_db_instance" "mlflow_auth_rds" {
  db_instance_identifier = "mlflow-auth"
}

data "aws_db_instance" "mlflow_rds" {
  db_instance_identifier = "mlflow"
}
