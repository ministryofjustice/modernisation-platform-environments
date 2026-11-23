module "waf" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/ab13c35
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/waf?ref=ab13c35"

  name                 = "${local.component_name}-${local.env_label}"
  alb_arn              = module.alb.alb_arn
  enable_managed_rules = false
  tags                 = local.tags

  # Block AppsTCFServer for all callers, matching ccms-ebs (SRE-211)
  blocked_uri_paths = ["/oa_html/appstcfserver"]

  ip_allowlist = [
    data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
    local.application_data.accounts[local.environment].mojo_devices,
    local.application_data.accounts[local.environment].dom1_devices,
    local.application_data.accounts[local.environment].moj_wifi,
  ]

  alarms = {
    topic_arn = data.aws_sns_topic.alerts.arn
  }
}
