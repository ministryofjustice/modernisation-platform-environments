resource "litellm_organization" "organisations" {
  for_each = local.environment_configuration.ai_gateway_configuration.organisations

  organization_alias = each.value.organization_alias

  depends_on = [
    helm_release.ai_gateway_configuration,
    helm_release.litellm,
    helm_release.litellm_admin
  ]
}
