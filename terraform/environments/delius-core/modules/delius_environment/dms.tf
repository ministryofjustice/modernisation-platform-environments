module "dms" {
  source         = "../components/dms"
  account_config = var.account_config
  account_info   = var.account_info
  tags           = var.tags
  env_name       = var.env_name
}
