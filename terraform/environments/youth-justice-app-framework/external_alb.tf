module "external_alb" {
  source = "./modules/alb"

  environment  = local.environment
  project_name = local.project_name
  vpc_id       = data.aws_vpc.shared.id
  tags         = local.tags

  alb_name = "yjaf-ext"
  internal = false
  #alb_route53_record_zone_id = module.private_dns_zone.aws_route53_zone_id #data.aws_route53_zone_id.inner.id

  listeners              = local.external_listeners
  existing_target_groups = module.internal_alb.target_group_arns


  alb_subnets_ids   = local.public_subnet_list[*].id
  web_acl_arn       = module.waf.waf_arn
  associate_web_acl = true
}
