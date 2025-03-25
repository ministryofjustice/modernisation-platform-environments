#tfsec:ignore:AWS0054 "This is an internal alb, the traffic only moves within the vpc and https is not required."
#tfsec:ignore:AVD-AWS-0054
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

  listeners          = local.internal_listeners
  target_groups      = local.target_groups
  enable_access_logs = true

  #pass in provider for creating records on central route53
  providers = {
    aws.core-network-services = aws.core-network-services
  }

}
