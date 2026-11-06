locals {
  private_subnets_cidr_blocks = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block,
  ]

  opahub_name    = "ccms-opahub"
  connector_name = "ccms-connector"
  adaptor_name   = "ccms-adaptor"

  # OPAHub runs on its own cluster; Connector and Service Adaptor share the second,
  # matching the split in the original ccms-oia stack
  opa_cluster_name      = "${local.component_name}-${local.env_label}-opa-cluster"
  conn_saa_cluster_name = "${local.component_name}-${local.env_label}-conn-saa-cluster"

  # Hostnames of this and the sibling feasibility components, all in the same external zone
  external_domain    = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  soa_hostname       = "ccms-soa-managed-${local.env_label}.${local.external_domain}"
  opahub_hostname    = "${local.opahub_name}-${local.env_label}.${local.external_domain}"
  connector_hostname = "${local.connector_name}-${local.env_label}.${local.external_domain}"

  soa_services_url = "https://${local.soa_hostname}/soa-infra/services/default"
  opa_answer_url   = "https://${local.opahub_hostname}/opa/determinations-server/answer/soap/12.2.1"
  opa_assess_url   = "https://${local.opahub_hostname}/opa/determinations-server/assess/soap/generic/12.2.1"
}
