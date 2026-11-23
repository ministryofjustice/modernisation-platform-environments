locals {
  private_subnets_cidr_blocks = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block,
  ]

  vpce_subnets_cidr_blocks = [
    data.aws_subnet.vpce_subnets_a.cidr_block,
    data.aws_subnet.vpce_subnets_b.cidr_block,
    data.aws_subnet.vpce_subnets_c.cidr_block,
  ]

  # Financial Transfers API, published as ccms-fin-transfer-<env_label>
  fin_transfer_name = "ccms-fin-transfer"

  # The alb module names the load balancer "<name>-alb", which must stay within 32 characters
  alb_name = "ccms-fin-xfer-${local.env_label}"

  cluster_name = "${local.component_name}-${local.env_label}-cluster"

  # Business Central inbound bucket and the folders the API and Lambda work in
  bc_bucket_name      = "${local.component_name}-${local.env_label}-bc-inbound"
  bc_bucket_base_path = "ccms-transfer-bc-${local.environment}"
  bc_bucket_folders = [
    "${local.bc_bucket_base_path}/inbound",
    "${local.bc_bucket_base_path}/archive",
    "${local.bc_bucket_base_path}/error",
  ]
}
