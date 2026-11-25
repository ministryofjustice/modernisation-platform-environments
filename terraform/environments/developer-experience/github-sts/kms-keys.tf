module "kms_key" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=d25e459bd43d8d0bdff7c250ba6b237a12be7381" # v4.2.2

  aliases = [local.component_name]
}
