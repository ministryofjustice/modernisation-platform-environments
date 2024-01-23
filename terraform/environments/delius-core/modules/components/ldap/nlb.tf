module "nlb" {
  source = "../../nlb"

 providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }
  app_name       = var.app_name
  env_name       = var.env_name
  internal       = true
  tags           = var.tags
  port           = 389
  protocol       = "TCP"
  subnet_ids     = var.account_config.private_subnet_ids
  vpc_cidr       = var.account_config.shared_vpc_cidr
  vpc_id         = var.account_config.shared_vpc_id
  zone_id = var.account_config.route53_inner_zone_info.zone_id
  mp_application_name = var.account_info.application_name
}