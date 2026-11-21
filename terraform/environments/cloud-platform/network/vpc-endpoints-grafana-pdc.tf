locals {
  # Do not use local.is-production: it also classifies nonlive workspaces as production.
  grafana_pdc_workspaces = toset([
    "cloud-platform-development",
    "cloud-platform-preproduction",
    "cloud-platform-nonlive",
    "container-platform-cd-nonlive",
    "container-platform-hmpps-nonlive",
    "container-platform-laa-nonlive",
    "container-platform-octo-nonlive",
  ])

  # prod-gb-south-1 services, shared by both Observability Platform Grafana Cloud stacks.
  grafana_pdc_services = {
    api = {
      service_name = "com.amazonaws.vpce.eu-west-2.vpce-svc-0b12fa07b304f0d79"
      port         = 443
    }
    gateway = {
      service_name = "com.amazonaws.vpce.eu-west-2.vpce-svc-04a3bf37de7c4c8be"
      port         = 22
    }
  }

  grafana_pdc_endpoints = {
    for key, service in local.grafana_pdc_services : key => service
    if contains(local.grafana_pdc_workspaces, terraform.workspace)
  }

  grafana_pdc_subnet_ids = {
    for key, service in data.aws_vpc_endpoint_service.grafana_pdc : key => [
      for index, az in module.cluster_vpc.azs : module.cluster_vpc.private_subnets[index]
      if contains(service.availability_zones, az)
    ]
  }

  # Allow agents on the primary VPC network or the secondary pod network, not other TGW spokes.
  grafana_pdc_ingress = {
    for rule in flatten([
      for key, service in local.grafana_pdc_endpoints : [
        for network, cidr in local.vpc_cidr[local.cp_vpc_name] : {
          key      = "${key}-${network}"
          endpoint = key
          cidr     = cidr
          port     = service.port
        }
      ]
    ]) : rule.key => rule
  }
}

data "aws_vpc_endpoint_service" "grafana_pdc" {
  for_each = local.grafana_pdc_endpoints

  service_name = each.value.service_name
}

resource "aws_security_group" "grafana_pdc" {
  #checkov:skip=CKV2_AWS_5: "Security group is attached to a VPC endpoint"
  for_each = local.grafana_pdc_endpoints

  name        = "${local.cp_vpc_name}-grafana-pdc-${each.key}"
  description = "Grafana PDC ${each.key} PrivateLink access from this VPC"
  vpc_id      = module.cluster_vpc.vpc_id

  tags = merge(local.tags, { Name = "${local.cp_vpc_name}-grafana-pdc-${each.key}" })
}

resource "aws_vpc_security_group_ingress_rule" "grafana_pdc" {
  for_each = local.grafana_pdc_ingress

  security_group_id = aws_security_group.grafana_pdc[each.value.endpoint].id
  description       = "Grafana PDC ${each.value.endpoint} access from this VPC"
  cidr_ipv4         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

resource "aws_vpc_endpoint" "grafana_pdc" {
  for_each = local.grafana_pdc_endpoints

  vpc_id              = module.cluster_vpc.vpc_id
  service_name        = each.value.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.grafana_pdc_subnet_ids[each.key]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.grafana_pdc[each.key].id]

  tags = merge(local.tags, { Name = "${local.cp_vpc_name}-grafana-pdc-${each.key}" })

  lifecycle {
    precondition {
      condition     = length(local.grafana_pdc_subnet_ids[each.key]) > 0
      error_message = "The Grafana PDC endpoint service must support at least one of this VPC's private subnet availability zones."
    }
  }
}
