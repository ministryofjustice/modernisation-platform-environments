module "daily-snapshots" {
  count       = local.is-development ? 1 : 0
  source      = "./dlm-snapshot"
  environment = local.environment
  service     = local.application_name
  tags        = local.tags
  target_tags = {
    is-production = "false"
  }
}