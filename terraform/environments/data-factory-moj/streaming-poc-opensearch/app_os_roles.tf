resource "opensearch_roles_mapping" "this" {
  for_each      = local.os_mappings
  role_name     = each.key
  backend_roles = each.value.backend_roles
  users         = each.value.users
}
