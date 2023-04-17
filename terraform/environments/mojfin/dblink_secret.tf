locals {
  dblink_secrets = {
    secret1 = {
      name          = "APP_MOJFIN_APPS_RO"
      description   = "APPS_RO password for mojfin db link"
      value         = random_password.apps_ro_password
    },
    secret2 = {
      name          = "APP_MOJFIN_DEVELOPER"
      description   = "DEVELOPER user for TAD and TAD_TEST db link"
      value = "laa_developer"
    },
    secret3 = {
      name          = "APP_MOJFIN_FEDUSER"
      description   = "FEDUSER user for EDW005"
      value = "fed1ser"
    },
    secret4 = {
      name          = "APP_MOJFIN_FINACC"
      description   = "FINACC user for CISRO db link"
      value = "Greenland"
    },
    secret5 = {
      name          = "APP_MOJFIN_MI_TEAM"
      description   = "ID for OBIEE connection to MOJFIN"
      value = "MI_TEAM1"
    },
    secret6 = {
      name          = "APP_MOJFIN_MORA-W"
      description   = "MORA-W user for CISPROD db link"
      value = "palace"
    },
    secret7 = {
      name          = "APP_MOJFIN_QUERY"
      description   = "Query user for CCMT db link"
      value = "query1"
    }

}

resource "random_password" "apps_ro_password" {
  length  = 10
  special = false
}

resource "aws_ssm_parameter" "secret" {
  for_each = local.dblink_secrets
  name        = each.value.name
  description = each.value.description
  type        = "SecureString"
  value       = each.value.value

  tags = merge(
    var.tags,
    { "Name" = each.value.name }
  )
}
