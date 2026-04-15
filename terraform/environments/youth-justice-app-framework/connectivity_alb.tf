#tfsec:ignore:AWS0054 "This is the connectivity alb, the traffic only moves within the vpc and https is not required."
#tfsec:ignore:AVD-AWS-0054
module "connectivity_alb" {
  source = "./modules/alb"

  environment     = local.environment
  project_name    = local.project_name
  vpc_id          = data.aws_vpc.shared.id
  alb_subnets_ids = local.private_subnet_list[*].id
  tags            = local.tags

  alb_name                   = "yjaf-connectivity"
  internal                   = true
  alb_route53_record_name    = "connectivity-lb"
  alb_route53_record_zone_id = data.aws_route53_zone.yjaf-inner.id

  listeners              = local.connectivity_listeners
  existing_target_groups = module.internal_alb.target_group_arns
  enable_access_logs     = true

  #pass in provider for creating records on central route53
  providers = {
    aws.core-network-services = aws.core-network-services
  }
}