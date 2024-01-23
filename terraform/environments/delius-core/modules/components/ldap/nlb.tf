module "nlb" {
  source = "../../nlb"

 providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name       = var.env_name
  internal       = true
  tags           = var.tags
  account_config = var.account_config
  account_info   = var.account_info
}