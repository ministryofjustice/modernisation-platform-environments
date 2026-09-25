# ------------------------------------------------------------------------------
# Downstream specials remediation
# ------------------------------------------------------------------------------

locals {
  specials_remediation_enabled = (
    local.is-preproduction || local.is-production
  )

  specials_remediation_prefix = (
    "specials-remediation/${local.environment_shorthand}"
  )

  specials_remediation_consumers = {
    ac = {
      consumer            = "AC"
      database            = "acquisitive_crime${local.dbt_suffix}"
      schedule_expression = "cron(0/6 * * * ? *)"
    }

    emdi = {
      consumer            = "EMDI"
      database            = "data_insights${local.dbt_suffix}"
      schedule_expression = "cron(3/6 * * * ? *)"
    }
  }

  specials_remediation_active_consumers = {
    for key, config in local.specials_remediation_consumers :
    key => config
    if local.specials_remediation_enabled
  }

  specials_remediation_databases = toset([
    for config in values(local.specials_remediation_consumers) :
    config.database
  ])
}