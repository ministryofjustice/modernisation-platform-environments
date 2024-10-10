
locals {

  loadbalancer_ingress_rules = {
    "lb_ingress" = {
      description     = "Loadbalancer ingress rule from CloudFront"
      from_port       = var.security_group_ingress_from_port
      to_port         = var.security_group_ingress_to_port
      protocol        = var.security_group_ingress_protocol
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
    }
  }

  loadbalancer_egress_rules = {
    "lb_egress" = {
      description     = "Loadbalancer egress rule"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }

  custom_header = "X-Custom-Header-LAA-${upper(var.application_name)}"

  external_lb_validation_records = {
    for dvo in aws_acm_certificate.external_lb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
      zone = lookup(
        local.route53_zones,
        dvo.domain_name,
        lookup(
          local.route53_zones,
          replace(dvo.domain_name, "/^[^.]*./", ""),
          lookup(
            local.route53_zones,
            replace(dvo.domain_name, "/^[^.]*.[^.]*./", ""),
            { provider = "external" }
      )))
    }
  }

  validation_records_external_lb = {
    for key, value in local.external_lb_validation_records : key => {
      name   = value.name
      record = value.record
      type   = value.type
    } if value.zone.provider == "external"
  }

  core_network_services_domains = {
    for domain, value in var.validation : domain => value if value.account == "core-network-services"
  }
  core_vpc_domains = {
    for domain, value in var.validation : domain => value if value.account == "core-vpc"
  }
  self_domains = {
    for domain, value in var.validation : domain => value if value.account == "self"
  }

  route53_zones = merge({
    for key, value in data.aws_route53_zone.core_network_services : key => merge(value, {
      provider = "core-network-services"
    })
    }, {
    for key, value in data.aws_route53_zone.core_vpc : key => merge(value, {
      provider = "core-vpc"
    })
    }, {
    for key, value in data.aws_route53_zone.self : key => merge(value, {
      provider = "self"
    })
  })

}



data "aws_vpc" "shared" {
  tags = {
    "Name" = var.vpc_all
  }
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}



# Terraform module which creates S3 Bucket resources for Load Balancer Access Logs on AWS.

module "s3-bucket" {
  count  = var.existing_bucket_name == "" ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.1.0"

  providers = {
    aws.bucket-replication = aws.bucket-replication
  }

  bucket_prefix       = "${var.application_name}-lb-access-logs"
  bucket_policy       = [data.aws_iam_policy_document.bucket_policy.json]
  replication_enabled = false
  versioning_enabled  = true
  force_destroy       = var.force_destroy_bucket
  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = var.tags
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [var.existing_bucket_name != "" ? "arn:aws:s3:::${var.existing_bucket_name}/${var.application_name}/AWSLogs/${var.account_number}/*" : "${module.s3-bucket[0].bucket.arn}/${var.application_name}/AWSLogs/${var.account_number}/*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.default.arn]
    }
  }
  statement {
    sid = "AWSLogDeliveryWrite"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [var.existing_bucket_name != "" ? "arn:aws:s3:::${var.existing_bucket_name}/${var.application_name}/AWSLogs/${var.account_number}/*" : "${module.s3-bucket[0].bucket.arn}/${var.application_name}/AWSLogs/${var.account_number}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      var.existing_bucket_name != "" ? "arn:aws:s3:::${var.existing_bucket_name}" : module.s3-bucket[0].bucket.arn
    ]
  }
}

data "aws_elb_service_account" "default" {}

#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "loadbalancer" {
  #checkov:skip=CKV_AWS_150:preventing destroy can be controlled outside of the module
  #checkov:skip=CKV2_AWS_28:WAF is configured outside of the module for more flexibility
  name                       = "${var.application_name}-application-external-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.lb.id]
  subnets                    = [var.public_subnets[0], var.public_subnets[1], var.public_subnets[2]]
  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.existing_bucket_name != "" ? var.existing_bucket_name : module.s3-bucket[0].bucket.id
    prefix  = var.application_name
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-alb"
    },
  )
}

resource "aws_security_group" "lb" {
  name        = "${var.application_name}-lb-security-group"
  description = "Controls access to the loadbalancer"
  vpc_id      = data.aws_vpc.shared.id

  dynamic "ingress" {
    for_each = local.loadbalancer_ingress_rules
    content {
      description     = lookup(ingress.value, "description", null)
      from_port       = lookup(ingress.value, "from_port", null)
      to_port         = lookup(ingress.value, "to_port", null)
      protocol        = lookup(ingress.value, "protocol", null)
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
      prefix_list_ids = lookup(ingress.value, "prefix_list_ids", null)
    }
  }

  dynamic "egress" {
    for_each = local.loadbalancer_egress_rules
    content {
      description     = lookup(egress.value, "description", null)
      from_port       = lookup(egress.value, "from_port", null)
      to_port         = lookup(egress.value, "to_port", null)
      protocol        = lookup(egress.value, "protocol", null)
      cidr_blocks     = lookup(egress.value, "cidr_blocks", null)
      security_groups = lookup(egress.value, "security_groups", null)
    }
  }
}

# ## Cloudfront


resource "random_password" "cloudfront" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "cloudfront" {
  name        = "cloudfront-v1-secret-${var.application_name}"
  description = "Simple secret created by AWS CloudFormation to be shared between ALB and CloudFront"
}

resource "aws_secretsmanager_secret_version" "cloudfront" {
  secret_id     = aws_secretsmanager_secret.cloudfront.id
  secret_string = random_password.cloudfront.result
}

# Importing the AWS secrets created previously using arn.
data "aws_secretsmanager_secret" "cloudfront" {
  arn = aws_secretsmanager_secret.cloudfront.arn
}

# Importing the AWS secret version created previously using arn.
data "aws_secretsmanager_secret_version" "cloudfront" {
  secret_id = data.aws_secretsmanager_secret.cloudfront.arn
}


## ALB Listener


# TODO This resource is required because otherwise Error: failed to read schema for module.alb.null_resource.always_run in registry.terraform.io/hashicorp/null: failed to instantiate provider
# When the whole stack is recreated this can be removed
resource "null_resource" "always_run" {
}



resource "aws_lb_listener" "alb_listener" {

  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = var.listener_port
  #checkov:skip=CKV_AWS_2:The ALB protocol is HTTP
  protocol        = var.listener_protocol #tfsec:ignore:aws-elb-http-not-used
  ssl_policy      = var.listener_protocol == "HTTPS" ? var.alb_ssl_policy : null
  certificate_arn = var.listener_protocol == "HTTPS" ? aws_acm_certificate_validation.external_lb_certificate_validation[0].certificate_arn : null # This needs the ARN of the certificate from Mod Platform

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied - must access via CloudFront"
      status_code  = 403
    }
  }

  tags = var.tags

}


resource "aws_lb_listener_rule" "alb_listener_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }

  condition {
    http_header {
      http_header_name = local.custom_header
      values           = [data.aws_secretsmanager_secret_version.cloudfront.secret_string]
    }
  }
}

resource "aws_lb_target_group" "alb_target_group" {
  name                 = "${var.application_name}-alb-tg"
  port                 = var.target_group_port
  protocol             = var.target_group_protocol
  vpc_id               = var.vpc_id
  deregistration_delay = var.target_group_deregistration_delay
  health_check {
    interval            = var.healthcheck_interval
    path                = var.healthcheck_path
    protocol            = var.healthcheck_protocol
    timeout             = var.healthcheck_timeout
    healthy_threshold   = var.healthcheck_healthy_threshold
    unhealthy_threshold = var.healthcheck_unhealthy_threshold
  }
  stickiness {
    enabled         = var.stickiness_enabled
    type            = var.stickiness_type
    cookie_duration = var.stickiness_cookie_duration
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-alb-tg"
    },
  )

}

resource "aws_athena_database" "lb-access-logs" {
  name   = "loadbalancer_access_logs"
  bucket = var.existing_bucket_name != "" ? var.existing_bucket_name : module.s3-bucket[0].bucket.id
  encryption_configuration {
    encryption_option = "SSE_S3"
  }
}

resource "aws_athena_named_query" "main" {
  name     = "${var.application_name}-create-table"
  database = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "${path.module}/templates/create_table.sql",
    {
      bucket     = var.existing_bucket_name != "" ? var.existing_bucket_name : module.s3-bucket[0].bucket.id
      account_id = var.account_number
      region     = var.region
    }
  )
}

resource "aws_athena_workgroup" "lb-access-logs" {
  name = "${var.application_name}-lb-access-logs"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = var.existing_bucket_name != "" ? "s3://${var.existing_bucket_name}/output/" : "s3://${module.s3-bucket[0].bucket.id}/output/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-lb-access-logs"
    }
  )

}



####### Certificates, Cert Validations & Route53 #######


## External LB Cert

resource "aws_acm_certificate" "external_lb" {

  domain_name               = var.acm_cert_domain_name
  validation_method         = "DNS"
  subject_alternative_names = var.environment == "production" ? null : ["${var.application_name}.${var.business_unit}-${var.environment}.${var.acm_cert_domain_name}"]
  tags                      = var.tags
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}


resource "aws_route53_record" "external_lb_validation_core_network_services" {
  provider = aws.core-network-services
  for_each = {
    for key, value in local.external_lb_validation_records : key => value if value.zone.provider == "core-network-services"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type

  # NOTE: value.zone is null indicates the validation zone could not be found
  # Ensure route53_zones variable contains the given validation zone or
  # explicitly provide the zone details in the validation variable.
  zone_id = each.value.zone.zone_id

  depends_on = [
    aws_acm_certificate.external_lb
  ]
}

# use core-vpc provider to validate business-unit domain
resource "aws_route53_record" "external_lb_validation_core_vpc" {
  provider = aws.core-vpc
  for_each = {
    for key, value in local.external_lb_validation_records : key => value if value.zone.provider == "core-vpc"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone.zone_id

  depends_on = [
    aws_acm_certificate.external_lb
  ]
}

# assume any other domains are defined in the current workspace
resource "aws_route53_record" "external_lb_validation_self" {
  for_each = {
    for key, value in local.external_lb_validation_records : key => value if value.zone.provider == "self"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone.zone_id

  depends_on = [
    aws_acm_certificate.external_lb
  ]
}

resource "aws_acm_certificate_validation" "external_lb_certificate_validation" {
  count           = (length(local.validation_records_external_lb) == 0 || var.external_validation_records_created) ? 1 : 0
  certificate_arn = aws_acm_certificate.external_lb.arn
  validation_record_fqdns = [
    for key, value in local.validation_records_external_lb : replace(value.name, "/\\.$/", "")
  ]
  depends_on = [
    aws_route53_record.external_lb_validation_core_network_services,
    aws_route53_record.external_lb_validation_core_vpc,
    aws_route53_record.external_lb_validation_self
  ]
}