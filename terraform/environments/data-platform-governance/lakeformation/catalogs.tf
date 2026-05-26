####################################################################################
# Glue / Lake Formation sub-catalogs
#
# One sub-catalog is created per factory defined in
# configuration/lakeformation.yml. Each factory's `domain` is used as the catalog
# name, and the corresponding consumer account is granted DESCRIBE on the
# catalog (with grant option) so Lake Formation will transparently create a RAM
# share. Both accounts sit inside the MoJ AWS Organization, so the share is
# auto-accepted by the consumer.
#
# Databases and tables can then be created inside this catalog (in this
# governance account) and the consumer account can create resource links
# pointing at them.
####################################################################################

locals {
  # Filter out factories that have no `domain` set (e.g. placeholder entries in
  # the YAML) so we only create catalogs that are fully configured.
  catalogs = {
    for factory_name, factory in try(local.lakeformation_configuration.factories, {}) :
    factory_name => {
      name       = factory.domain
      account_id = local.environment_management.account_ids[factory_name]
    }
    if try(factory.domain, null) != null
  }
}

resource "aws_glue_catalog" "main" {
  for_each = local.catalogs

  name        = each.value.name
  description = "Lake Formation catalog for ${each.key}"

  tags = merge(
    local.tags,
    {
      "justice-data-factory"     = each.key
      "justice-data-lake-domain" = each.value.name
    }
  )
}

# Share the catalog with the consumer account. Granting DESCRIBE to an external
# account ID causes Lake Formation to create the underlying RAM share; the
# WITH GRANT OPTION lets the consumer account re-grant permissions on resources
# inside the catalog to its own IAM principals.
resource "aws_lakeformation_permissions" "catalog_share" {
  for_each = local.catalogs

  principal                     = each.value.account_id
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]

  catalog_resource = true
  catalog_id       = "${data.aws_caller_identity.current.account_id}:${aws_glue_catalog.main[each.key].name}"
}
