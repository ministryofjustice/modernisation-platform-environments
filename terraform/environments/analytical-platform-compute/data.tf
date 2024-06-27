data "aws_availability_zones" "available" {}

data "aws_ec2_transit_gateway" "pttp" {
  id = "tgw-026162f1ba39ce704"
}

# data "aws_ram_resource_share" "moj_tgw" {
#   filter {
#     name   = "resourceType"
#     values = ["ec2:TransitGateway"]
#   }
# }

# data "aws_arn" "moj_tgw" {
#   arn = data.aws_ram_resource_share.moj_tgw.resource_arns[0]
# }

# TODO: revisit this to unhardcode the tgw ID above
# data "aws_ram_resource_share" "tgw_moj" {
#   name           = "tgw-moj"
#   resource_owner = "OTHER-ACCOUNTS"
# }

# data "aws_ec2_transit_gateway" "pttp" {
#   filter {
#     name   = "owner-id"
#     values = [data.aws_ram_resource_share.tgw_moj.resource_arns]
#   }
# }

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
