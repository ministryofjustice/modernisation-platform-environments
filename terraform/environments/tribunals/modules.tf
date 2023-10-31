module "ecs_loadbalancer" {
  source                            = "./modules/ecs_loadbalancer"
  app_name                          = "tribunals" #var.app_name
  tags_common                       = local.tags
  vpc_shared_id                     = data.aws_vpc.shared.id
  application_data                  = local.application_data.accounts[local.environment]
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  aws_acm_certificate_external      = aws_acm_certificate.external
}