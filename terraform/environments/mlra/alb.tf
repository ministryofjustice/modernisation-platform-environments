module "alb" {
  source = "./modules/alb"
  providers = {
    aws.bucket-replication = aws
  }

  vpc_all                          = local.vpc_all
  application_name                 = local.application_name
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
  ingress_cidr_block               = local.application_data.accounts[local.environment].moj_vpn_cidr
  internal_lb                      = true
  # existing_bucket_name = "" # An s3 bucket name can be provided in the module by adding the `existing_bucket_name` variable and adding the bucket name

  listener_protocol = "HTTP"
  listener_port     = 80

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
