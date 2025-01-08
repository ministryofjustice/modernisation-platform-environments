module "internal_alb" {
  source = "./modules/alb"

  environment     = local.environment
  project_name    = local.project_name
  vpc_id          = data.aws_vpc.shared.id
  alb_subnets_ids = local.private_subnet_list[*].id
  tags            = local.tags

  alb_name                   = "yjaf-int"
  internal                   = true
  alb_route53_record_name    = "private-lb"
  alb_route53_record_zone_id = data.aws_route53_zone.yjaf-inner.id

  listeners     = local.internal_listeners
  target_groups = local.target_groups
}
