

# resource "aws_athena_data_catalog" "this" {
#   # for_each    = { for index, value in lookup(local.audit_share_map, var.env_name, []) : index => value }
#   name        = "athena-audit-dc-${var.env_name}"
#   description = "Audit data catalog for ${var.env_name}"
#   type        = "GLUE"

#   # parameters = {
#   #   "catalog-id" = var.platform_vars.environment_management.account_ids[each.value.account]
#   #   # "catalog-id" = var.account_info.id
#   # }
#   parameters = { for key, value in lookup(local.audit_share_map, var.env_name, {}) : "catalog-id" => var.platform_vars.environment_management.account_ids[value.account] }


#   tags = {
#     Name = "athena-audit-data-catalog-${var.env_name}"
#   }
# }
