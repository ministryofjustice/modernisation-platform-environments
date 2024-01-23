module "nlb" {
  source = "../../nlb"

  env_name       = var.env_name
  internal       = true
  tags           = var.tags
  account_config = var.account_config
  account_info   = var.account_info
}