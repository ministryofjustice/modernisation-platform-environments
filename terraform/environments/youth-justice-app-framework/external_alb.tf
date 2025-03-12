#tfsec:ignore:AWS0053 "The load balancer is internet facing by design."
#tfsec:ignore:AVD-AWS-0053
module "external_alb" {
  #checkov:skip=CKV_AWS_2:false alert
  source = "./modules/alb"
  #pass in provider for creating records on central route53
  providers = {
    aws.core-network-services = aws.core-network-services
  }

  environment  = local.environment
  project_name = local.project_name
  vpc_id       = data.aws_vpc.shared.id
  tags         = local.tags

  alb_name = "yjaf-ext"
  internal = false
  #alb_route53_record_zone_id = module.private_dns_zone.aws_route53_zone_id #data.aws_route53_zone_id.inner.id

  listeners              = local.external_listeners
  existing_target_groups = module.internal_alb.target_group_arns

  alb_ingress_with_cidr_blocks_rules = [
    {
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  enable_access_logs = true
  alb_subnets_ids    = local.public_subnet_list[*].id
  web_acl_arn        = module.waf.waf_arn
  associate_web_acl  = true
}
