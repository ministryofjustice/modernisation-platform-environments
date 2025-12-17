locals {
  data_subnets_cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block
  ]

  private_subnets_cidr_blocks = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]

  aws_account_id            = data.aws_caller_identity.current.account_id
  logging_bucket_name       = "${local.application_data.accounts[local.environment].app_name}-${local.environment}-logging"
  lb_log_prefix_soa_admin   = "${local.application_data.accounts[local.environment].app_name}-admin-lb"
  lb_log_prefix_soa_managed = "${local.application_data.accounts[local.environment].app_name}-managed-lb"

  # Folders created on S3 for Lambda artifacts
  lambda_folder_name = [
    "lambda_delivery",
    "${local.application_name}-edn-quiesced-layer"
  ]

  # Detect change in Lambda code to force new publish
  lambda_source_hashes = [
    for f in fileset("${path.module}/lambda/ccms-soa-edn-quiesced", "**") :
    sha256(file("${path.module}/lambda/ccms-soa-edn-quiesced/${f}"))
  ]
}
