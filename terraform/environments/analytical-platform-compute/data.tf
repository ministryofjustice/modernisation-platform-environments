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

data "aws_subnets" "shared_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private*"
  }
}

data "aws_subnet" "shared_private_subnets_a" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "shared_private_subnets_b" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}b"
  }
}

data "aws_subnet" "shared_private_subnets_c" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}c"
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
