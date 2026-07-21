module "waf" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/08ee30f
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/waf?ref=08ee30f"

  name    = "${local.component_name}-${local.env_label}"
  alb_arn = module.alb.alb_arn
  tags    = local.tags
}
