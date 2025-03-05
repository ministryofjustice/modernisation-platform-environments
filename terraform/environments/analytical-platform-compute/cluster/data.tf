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

data "aws_subnet" "intra_subnet_eu_west_2a" {
  filter {
    name   = "tag:Name"
    values = ["${local.our_vpc_name}-intra-eu-west-2a"]
  }
}

data "aws_subnet" "intra_subnet_eu_west_2b" {
  filter {
    name   = "tag:Name"
    values = ["${local.our_vpc_name}-intra-eu-west-2b"]
  }
}
data "aws_subnet" "intra_subnet_eu_west_2c" {
  filter {
    name   = "tag:Name"
    values = ["${local.our_vpc_name}-intra-eu-west-2c"]
  }
}
