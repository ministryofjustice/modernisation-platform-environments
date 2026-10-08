mock_provider "aws" {}

mock_provider "aws" {
  alias = "us_east_1"
}

variables {
  tags = { environment = "test" }
  configuration = {
    domain_name        = "ai-prototype.modernisation-platform.service.justice.gov.uk"
    hosted_zone_id     = "Z123456789"
    certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/test"
    bucket_prefix      = "shared-prototype-edge-test"
    allowed_ipv4_cidrs = ["192.0.2.0/24"]
  }
}

run "shared_hosting" {
  command = plan

  assert {
    condition     = output.hosting.prototype_url_template == "https://{prototype-id}.ai-prototype.modernisation-platform.service.justice.gov.uk" && output.hosting.upload_prefix_template == "{prototype-id}/"
    error_message = "The shared edge must provide a URL and upload-prefix template for arbitrarily many registered prototypes."
  }

  assert {
    condition     = length(aws_cloudfront_function.route.key_value_store_associations) == 1
    error_message = "The stable routing function must read its prototype registry from CloudFront KeyValueStore."
  }
}

run "reject_unconfigured_hosting" {
  command = plan
  variables {
    configuration = {
      domain_name        = ""
      hosted_zone_id     = ""
      certificate_arn    = ""
      bucket_prefix      = ""
      allowed_ipv4_cidrs = []
    }
  }
  expect_failures = [var.configuration]
}

run "shared_registry_store" {
  command = plan
  assert {
    condition     = aws_cloudfront_key_value_store.prototypes.name == "shared-prototype-edge-test-prototypes"
    error_message = "The environment must provide one shared registry independent of the number of prototype builds."
  }
}

run "reject_public_allowlist" {
  command = plan
  variables {
    configuration = {
      domain_name        = "ai-prototype.modernisation-platform.service.justice.gov.uk"
      hosted_zone_id     = "Z123456789"
      certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/test"
      bucket_prefix      = "shared-prototype-edge-test"
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
      aws_cloudfront_distribution.shared.aliases == toset(["*.ai-prototype.modernisation-platform.service.justice.gov.uk"]) &&
      length(aws_cloudfront_distribution.shared.origin) == 1 &&
      length(aws_cloudfront_distribution.shared.custom_error_response) == 0 &&
      one(aws_cloudfront_distribution.shared.default_cache_behavior[0].function_association).event_type == "viewer-request"
    )
    error_message = "All prototype subdomains must share one origin and rewrite before cache lookup, without a global error fallback."
  }

  assert {
    condition = (
      module.prototypes.bucket.force_destroy == false &&
      one(module.prototypes.bucket_server_side_encryption.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256" &&
      aws_cloudfront_origin_access_control.prototypes.signing_behavior == "always"
    )
    error_message = "Prototype content must use the shared bucket module with SSE-S3 and non-destructive lifecycle settings."
  }
}
