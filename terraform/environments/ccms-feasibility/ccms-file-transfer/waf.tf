module "waf" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/ab13c35
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/waf?ref=ab13c35"

  name    = local.alb_name
  alb_arn = module.alb.alb_arn
  tags    = local.tags

  ip_allowlist = concat(
    local.private_subnets_cidr_blocks,
    [local.application_data.accounts[local.environment].aws_workspace],
  )

  managed_rule_overrides = [
    { name = "SizeRestrictions_BODY", action = "count" },
    { name = "CrossSiteScripting_BODY", action = "count" },
  ]

  alarms = {
    topic_arn = data.aws_sns_topic.alerts.arn
  }
}
