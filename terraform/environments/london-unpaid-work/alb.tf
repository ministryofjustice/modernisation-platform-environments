module "web_alb" {
  source = "./modules/alb"

  name              = "london-unpaid-work-web-alb"
  subnets           = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id, data.aws_subnet.public_subnets_c.id]
  vpc_id            = data.aws_vpc.shared.id
  security_group_id = aws_security_group.london_unpaid_work_alb.id
  tags              = local.tags

  access_logs_bucket = aws_s3_bucket.alb_access_logs.bucket
  certificate_arn    = null # placeholder: normally sourced from core-vpc strategic public SSL outputs

  target_group_name = "london-unpaid-work-web-target-group"
  target_group_port = 80
  healthcheck_path  = "/index.html"
}

module "api_alb" {
  source = "./modules/alb"

  name              = "london-unpaid-work-api-alb"
  subnets           = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id, data.aws_subnet.public_subnets_c.id]
  vpc_id            = data.aws_vpc.shared.id
  security_group_id = aws_security_group.london_unpaid_work_alb.id
  tags              = local.tags

  access_logs_bucket = aws_s3_bucket.alb_access_logs.bucket
  certificate_arn    = null # placeholder: normally sourced from core-vpc strategic public SSL outputs

  target_group_name = "london-unpaid-work-api-target-group"
  target_group_port = 80
  healthcheck_path  = "/karma.html" # legacy API health check path
}
