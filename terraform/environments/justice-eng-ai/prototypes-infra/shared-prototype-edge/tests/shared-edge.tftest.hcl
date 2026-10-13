mock_provider "aws" {}

mock_provider "aws" {
  alias = "us_east_1"
}

variables {
  tags = { environment = "test" }
  configuration = {
    domain_name        = "ai-builder.modernisation-platform.service.justice.gov.uk"
    hosted_zone_id     = "Z123456789"
    certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/test"
    name_prefix        = "shared-prototype-edge-test"
    vpc_id             = "vpc-0123456789abcdef0"
    private_subnet_ids = ["subnet-a", "subnet-b", "subnet-c"]
    allowed_ipv4_cidrs = ["192.0.2.0/24"]
  }
}

run "shared_hosting" {
  command = plan

  assert {
    condition     = output.hosting.prototype_url_template == "https://{prototype-id}.ai-builder.modernisation-platform.service.justice.gov.uk"
    error_message = "The shared edge must provide the ai-builder preview URL template."
  }
}

run "reject_unconfigured_hosting" {
  command = plan
  variables {
    configuration = {
      domain_name        = ""
      hosted_zone_id     = ""
      certificate_arn    = ""
      name_prefix        = ""
      vpc_id             = ""
      private_subnet_ids = []
      allowed_ipv4_cidrs = []
    }
  }
  expect_failures = [var.configuration]
}

run "shared_private_alb_origin" {
  command = plan
  assert {
    condition = (
      aws_lb.shared.internal &&
      one(aws_lb_listener.shared.default_action).fixed_response[0].status_code == "404" &&
      length(one(aws_cloudfront_distribution.shared.origin).vpc_origin_config) == 1
    )
    error_message = "CloudFront must use a private ALB VPC origin with a 404 default until a prototype host rule is installed."
  }
}

run "reject_public_allowlist" {
  command = plan
  variables {
    configuration = {
      domain_name        = "ai-builder.modernisation-platform.service.justice.gov.uk"
      hosted_zone_id     = "Z123456789"
      certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/test"
      name_prefix        = "shared-prototype-edge-test"
      vpc_id             = "vpc-0123456789abcdef0"
      private_subnet_ids = ["subnet-a", "subnet-b", "subnet-c"]
      allowed_ipv4_cidrs = ["0.0.0.0/0"]
    }
  }
  expect_failures = [var.configuration]
}

run "shared_security" {
  command = plan

  assert {
    condition = (
      length(aws_wafv2_web_acl.shared.default_action[0].allow) == 1 &&
      alltrue([for rule in aws_wafv2_web_acl.shared.rule : length(rule.action) == 0 ? true : length(rule.action[0].allow) == 0]) &&
      [for rule in aws_wafv2_web_acl.shared.rule : rule.priority if rule.name == "BlockOutsideAllowedNetworks"][0] == 0 &&
      alltrue([for rule in aws_wafv2_web_acl.shared.rule : rule.priority > 0 if rule.name != "BlockOutsideAllowedNetworks"])
    )
    error_message = "Block outsiders first; permitted IPs must not bypass managed security rules through a terminating allow rule."
  }

  assert {
    condition = (
      aws_cloudfront_distribution.shared.aliases == toset(["*.ai-builder.modernisation-platform.service.justice.gov.uk"]) &&
      length(aws_cloudfront_distribution.shared.origin) == 1 &&
      aws_cloudfront_vpc_origin.shared.vpc_origin_endpoint_config[0].origin_protocol_policy == "http-only"
    )
    error_message = "All prototype subdomains must share the CloudFront distribution and private ALB origin."
  }

  assert {
    condition     = aws_security_group.alb.vpc_id == var.configuration.vpc_id
    error_message = "The private ALB must be created in the environment VPC."
  }
}
