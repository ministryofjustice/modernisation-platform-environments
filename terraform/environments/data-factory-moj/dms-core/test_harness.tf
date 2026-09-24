module "dms_test_harness" {
  count = local.dms_core_enabled ? 1 : 0

  source = "./modules/dms-test-harness"

  name = "${local.application_name}-${local.environment}-${local.component_name}"

  vpc_id         = data.aws_vpc.shared[0].id
  subnet_ids     = data.aws_subnets.shared-data[0].ids
  kms_key_arn    = data.aws_kms_key.general_shared.arn
  seed_image_uri = "${aws_ecr_repository.dms_seed[0].repository_url}:dms-seed-v4"

  allocated_storage     = 40
  max_allocated_storage = 100

  tags = local.tags
}
