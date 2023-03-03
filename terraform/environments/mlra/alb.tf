module "alb" {
  source = "./modules/alb"
  providers = {
    aws.bucket-replication = aws
    aws.core-vpc = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  vpc_all                          = local.vpc_all
  application_name                 = local.application_name
  business_unit                    = var.networking[0].business-unit
  public_subnets                   = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id, data.aws_subnet.public_subnets_c.id]
  private_subnets                  = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  tags                             = local.tags
  account_number                   = local.environment_management.account_ids[terraform.workspace]
  environment                      = local.environment
  region                           = "eu-west-2"
  enable_deletion_protection       = false
  idle_timeout                     = 60
  force_destroy_bucket             = true
  security_group_ingress_from_port = 443
  security_group_ingress_to_port   = 443
  security_group_ingress_protocol  = "tcp"
  moj_vpn_cidr_block               = local.application_data.accounts[local.environment].moj_vpn_cidr
  # existing_bucket_name = "" # An s3 bucket name can be provided in the module by adding the `existing_bucket_name` variable and adding the bucket name

  listener_protocol = "HTTPS" # TODO This needs changing to HTTPS as part of https://dsdmoj.atlassian.net/browse/LAWS-3076
  listener_port     = 443
  alb_ssl_policy    = "ELBSecurityPolicy-TLS-1-2-2017-01" # TODO This enforces TLSv1.2. For general, use ELBSecurityPolicy-2016-08 instead
  services_zone_id   = data.aws_route53_zone.network-services.zone_id
  external_zone_id  = data.aws_route53_zone.external.zone_id

  target_group_deregistration_delay = 30
  target_group_protocol             = "HTTP"
  target_group_port                 = 80
  vpc_id                            = data.aws_vpc.shared.id

  healthcheck_interval            = 15
  healthcheck_path                = "/mlra/"
  healthcheck_protocol            = "HTTP"
  healthcheck_timeout             = 5
  healthcheck_healthy_threshold   = 2
  healthcheck_unhealthy_threshold = 3

  stickiness_enabled         = true
  stickiness_type            = "lb_cookie"
  stickiness_cookie_duration = 10800
}
