module "auth0_log_streams" {
  source = "./modules/auth0-log-streams"

  for_each = local.environment_configuration.auth0_log_streams

  name              = each.key
  event_source_name = each.value.event_source_name

  tags = local.tags
}
