module "waf" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/546ba54
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/waf?ref=546ba54"

  name                 = "${local.component_name}-${local.env_label}"
  alb_arn              = module.alb.alb_arn
  enable_managed_rules = false
  tags                 = local.tags

  ip_allowlist = concat(
    local.private_subnets_cidr_blocks,
    [local.application_data.accounts[local.environment].aws_workspace],
  )
}
