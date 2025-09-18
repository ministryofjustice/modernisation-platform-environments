module "kms_key" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=83e5418372a0716f6dae00ef04eaf42110f9f072" # v4.1.0

  aliases               = ["s3/mojdp-${local.environment}-${local.component_name}"]
  enable_default_policy = true

  deletion_window_in_days = 7
}
