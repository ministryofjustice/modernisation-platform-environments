resource "litellm_organization" "organisations" {
  for_each = try(local.ai_gateway_configuration.organisations, {})

  organization_alias = try(each.value.alias, each.key)

  depends_on = [
    helm_release.ai_gateway_configuration,
    helm_release.litellm,
    helm_release.litellm_admin
  ]
}
