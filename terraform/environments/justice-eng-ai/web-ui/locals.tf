locals {
  # Base name shared by the UI's ALB, target group, ECS cluster/service etc.
  # No environment suffix needed -- development and production are separate
  # AWS accounts, so there's no naming collision to avoid within an account.
  application_resource_name = "${local.application_name}-ui"

  # Per-environment hostnames come from application_variables.json (see
  # local.application_data in platform_locals.tf) so dev and prod stay
  # distinct without hardcoding environment logic here.
  builder_hostname = var.builder_hostname != "" ? var.builder_hostname : local.application_data.accounts[local.environment].builder_hostname

  # var.forge_package_s3_bucket stays an explicit override (and keeps the
  # bucket un-managed by this root -- see its description), but falls back
  # to the backend-processing root's staging bucket, now that one exists in
  # every account, rather than requiring every environment to set it.
  # try() guards against backend-processing not having been applied with
  # its staging_bucket_name output yet -- remove once it has been.
  forge_package_s3_bucket = var.forge_package_s3_bucket != "" ? var.forge_package_s3_bucket : try(data.terraform_remote_state.backend_processing.outputs.staging_bucket_name, "")

  # The staging bucket enforces an explicit-deny bucket policy unless
  # PutObject requests declare this exact KMS key id -- see
  # forge_ecs_task_package_s3 in forge-journey-lab.tf, which passes it to
  # Forge as FORGE_PACKAGE_S3_KMS_KEY_ARN.
  forge_package_s3_kms_key_arn = try(data.terraform_remote_state.backend_processing.outputs.staging_bucket_kms_key_arn, "")

  # Private subnets for ECS/EFS, sourced from the shared-VPC lookups
  # defined in platform_data.tf (data.aws_vpc.shared et al).
  private_subnet_ids = [
    data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_b.id,
    data.aws_subnet.private_subnets_c.id,
  ]

  private_subnets_by_key = {
    a = data.aws_subnet.private_subnets_a.id
    b = data.aws_subnet.private_subnets_b.id
    c = data.aws_subnet.private_subnets_c.id
  }
}
