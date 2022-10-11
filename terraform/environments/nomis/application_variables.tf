# See nomis-development.tf etc for the environment specific settings
locals {
  accounts = {
    development   = local.nomis_development
    test          = local.nomis_test
    preproduction = local.nomis_preproduction
    production    = local.nomis_production
  }
}
