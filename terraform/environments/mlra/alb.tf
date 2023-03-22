module "alb" {
  source = "./modules/alb"
  providers = {
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
    aws.us-east-1             = aws.us-east-1
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

  listener_protocol    = "HTTPS"
  listener_port        = 443
  alb_ssl_policy       = "ELBSecurityPolicy-TLS-1-2-2017-01" # TODO This enforces TLSv1.2. For general, use ELBSecurityPolicy-2016-08 instead

  services_zone_id     = data.aws_route53_zone.network-services.zone_id
  external_zone_id     = data.aws_route53_zone.external.zone_id
  acm_cert_domain_name = local.application_data.accounts[local.environment].acm_cert_domain_name

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

  # CloudFront settings, to be moved to application_variables.json if there are differences between environments
  cloudfront_default_cache_behavior = {
    smooth_streaming = false
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["HEAD", "GET"]
    forwarded_values_query_string = true
    forwarded_values_headers = ["Authorization", "CloudFront-Forwarded-Proto", "CloudFront-Is-Desktop-Viewer", "CloudFront-Is-Mobile-Viewer", "CloudFront-Is-SmartTV-Viewer", "CloudFront-Is-Tablet-Viewer", "CloudFront-Viewer-Country", "Host", "User-Agent"]
    forwarded_values_cookies_forward = "whitelist"
    forwarded_values_cookies_whitelisted_names = ["AWSALB", "JSESSIONID"]
    viewer_protocol_policy = "https-only"
  }
  # Other cache behaviors are processed in the order in which they're listed in the CloudFront console or, if you're using the CloudFront API, the order in which they're listed in the DistributionConfig element for the distribution.
  cloudfront_ordered_cache_behavior = {
    "cache_behavior_0" = {
      smooth_streaming = false
      path_pattern     = "*.png"
      min_ttl                = 0
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["HEAD", "GET"]
      forwarded_values_query_string = false
      forwarded_values_headers      = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy = "https-only"
    },
    "cache_behavior_1" = {
      smooth_streaming = false
      path_pattern     = "*.jpg"
      min_ttl                = 0
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["HEAD", "GET"]
      forwarded_values_query_string = false
      forwarded_values_headers      = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy = "https-only"
    },
    "cache_behavior_2" = {
      smooth_streaming = false
      path_pattern     = "*.gif"
      min_ttl                = 0
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["HEAD", "GET"]
      forwarded_values_query_string = false
      forwarded_values_headers      = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy = "https-only"
    },
    "cache_behavior_3" = {
      smooth_streaming = false
      path_pattern     = "*.css"
      min_ttl                = 0
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["HEAD", "GET"]
      forwarded_values_query_string = false
      forwarded_values_headers      = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy = "https-only"
    },
    "cache_behavior_4" = {
      smooth_streaming = false
      path_pattern     = "*.js"
      min_ttl                = 0
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["HEAD", "GET"]
      forwarded_values_query_string = false
      forwarded_values_headers      = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy = "https-only"
    }
  }
  cloudfront_http_version = "http2"
  cloudfront_enabled = true
  cloudfront_origin_protocol_policy = "https-only"
  cloudfront_origin_read_timeout = 60
  cloudfront_origin_keepalive_timeout = 60
  cloudfront_price_class = "PriceClass_100"
  cloudfront_geo_restriction_type = "none"
  cloudfront_geo_restriction_location = []
  cloudfront_is_ipv6_enabled = true
  waf_default_action = "BLOCK"

}
