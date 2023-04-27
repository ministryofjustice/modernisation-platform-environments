###########################################################################################
#------------------------Comment out file if not required----------------------------------
###########################################################################################

resource "aws_acm_certificate" "example_cert" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = [
    format("%s.%s.%s.modernisation-platform.service.justice.gov.uk", local.application_name, var.networking[0].business-unit, local.environment),
  ]

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-certificate", local.application_name, local.environment)) }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "example_cert" {
  certificate_arn         = aws_acm_certificate.example_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.example_cert_validation : record.fqdn]
  timeouts {
    create = "10m"
  }
}

resource "aws_route53_record" "example_cert_validation" {
  provider = aws.core-network-services
  for_each = {
    for dvo in aws_acm_certificate.example_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.network-services.zone_id
}


# This will build on the core-vpc development account under platforms-development.modernisation-platform.service.justice.gov.uk, and route traffic back to example LB
resource "aws_route53_record" "example_core_vpc" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform-core-vpc.service.justice.gov.uk"
  type    = "A"

  alias {
    name = aws_lb.certificate_example_lb.dns_name
    zone_id = aws_lb.certificate_example_lb.zone_id
    evaluate_target_health = true
  }
}

# Build loadbalancer
#tfsec:ignore:aws-elb-alb-not-public as the external lb needs to be public.
resource "aws_lb" "certificate_example_lb" {
  name               = "certificate-example-loadbalancer"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.shared-public.ids
  #checkov:skip=CKV_AWS_150:Short-lived example environment, hence no need for deletion protection
  enable_deletion_protection = false
  # allow 60*4 seconds before 504 gateway timeout for long-running DB operations
  idle_timeout               = 240
  drop_invalid_header_fields = true

  security_groups = [aws_security_group.certificate_example_load_balancer_sg.id]

  access_logs {
    bucket  = module.s3-bucket-lb.bucket.id
    prefix  = "test-lb"
    enabled = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-external-loadbalancer"
    }
  )
  depends_on = [aws_security_group.certificate_example_load_balancer_sg]
}

resource "aws_security_group" "certificate_example_load_balancer_sg" {
  name        = "certificate-example-lb-sg"
  description = "controls access to load balancer"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("lb-sg-%s-%s-example", local.application_name, local.environment)) }
  )
}