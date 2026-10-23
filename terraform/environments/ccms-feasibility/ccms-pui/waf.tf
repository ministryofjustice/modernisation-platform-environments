module "waf" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/10d2292
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/waf?ref=10d2292"

  name                 = "${local.component_name}-${local.env_label}"
  alb_arn              = module.alb.alb_arn
  enable_managed_rules = false
  tags                 = local.tags

  ip_allowlist = concat(
    local.private_subnets_cidr_blocks,
    [local.application_data.accounts[local.environment].aws_workspace],
  )

  alarms = {
    topic_arn = data.aws_sns_topic.alerts.arn
  }
}
