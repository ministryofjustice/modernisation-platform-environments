module "dms_test_harness" {
  count = local.dms_core_enabled ? 1 : 0

  source = "./modules/dms-test-harness"

  name = "${local.application_name}-${local.environment}-${local.component_name}"

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = data.aws_subnets.shared-data.ids

  tags = local.tags
}
