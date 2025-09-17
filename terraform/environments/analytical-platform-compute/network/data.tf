data "aws_availability_zones" "available" {}

data "aws_ec2_transit_gateway" "moj_tgw" {
  id = "tgw-026162f1ba39ce704"
}

# Application Load Balancer
data "aws_lb" "mwaa_alb" {
  name = "mwaa"
}

data "aws_route53_resolver_query_log_config" "core_logging_s3" {
  filter {
    name   = "Name"
    values = ["core-logging-rlq-s3"]
  }
}
