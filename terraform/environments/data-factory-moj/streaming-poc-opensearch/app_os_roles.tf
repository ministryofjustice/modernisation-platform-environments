resource "opensearch_roles_mapping" "this" {
  for_each = var.opensearch_role_mappings

  role_name     = each.key
  backend_roles = each.value.backend_roles
  users         = each.value.users
}
