module "development" {
  count                   = local.is-development == "-development" ? 1 : 0
  source                  = "../../modules/patch_manager"
  application             = "hmpps-domain-services"
  environment             = "development"
  schedule                = "cron(15 16 ? * * *)" # 4.15pm today
  approved_patches        = ["KB5034682", "KB5034770"]
}

