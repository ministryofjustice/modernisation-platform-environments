locals {
  private_subnets_cidr_blocks = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block,
  ]

  data_subnets_cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block,
  ]

  # EBS DB listener ports
  db_ports = [1521, 1522]

  # Hostnames of this and the sibling feasibility components, all in the same external zone
  external_domain    = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  pui_hostname       = "${local.component_name}-${local.env_label}.${local.external_domain}"
  soa_hostname       = "ccms-soa-managed-${local.env_label}.${local.external_domain}"
  opahub_hostname    = "ccms-opahub-${local.env_label}.${local.external_domain}"
  connector_hostname = "ccms-connector-${local.env_label}.${local.external_domain}"
  clamav_hostname    = "ccms-clamav-${local.env_label}.${local.external_domain}"

  soa_services_url = "https://${local.soa_hostname}/soa-infra/services/default"
  owd_base_url     = "https://${local.opahub_hostname}/opa/web-determinations"

  docs_bucket_name = "${local.component_name}-${local.env_label}-docs"
}
