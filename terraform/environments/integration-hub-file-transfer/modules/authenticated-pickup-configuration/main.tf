module "transfer_identity" {
  source = "../transfer-web-app-identity-configuration"
}

locals {
  recipients_by_environment = {
    development   = local.development
    test          = local.test
    preproduction = local.preproduction
    production    = local.production
  }
}
