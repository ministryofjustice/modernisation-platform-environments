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
}
