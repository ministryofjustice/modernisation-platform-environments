##
# Define local vars that are used in a few placed
##
locals {
  domain_full_name  = "${local.application_name}-${local.environment}.local"
  domain_short_name = "${replace(local.application_name, "delius-", "")}-${local.application_data.accounts[local.environment].short_environment_name}" # e.g. form "iaps-dev" because we need <= 15 chars for NETBIOS name 
  domain_dns_ips    = sort(aws_directory_service_directory.active_directory.dns_ip_addresses)
}

##
# Create Managed AD
##
resource "aws_directory_service_directory" "active_directory" {
  name        = local.domain_full_name
  short_name  = local.domain_short_name
  description = "Microsoft AD for ${local.domain_full_name}"

  type    = "MicrosoftAD"
  edition = "Standard"

  password   = aws_secretsmanager_secret_version.ad_password.secret_string
  enable_sso = false

  vpc_settings {
    vpc_id     = data.aws_vpc.shared.id
    subnet_ids = slice(data.aws_subnets.shared-private.ids, 0, 2) # Retrieve the first 2 subnet ids - must be 2 because 2 DCs are created
  }

  tags = merge(
    local.tags,
    {},
  )

  # Required as AWS does not allow you to change the Admin password post AD Create - you must destroy/recreate 
  # When we run tf plan against an already created AD it will always show the AD needs destroy/create so we ignore
  lifecycle {
    ignore_changes = [
      password
    ]
  }
}

##
# Set up logging for the Managed AD
#
#checkov:skip=CKV_AWS_158
resource "aws_cloudwatch_log_group" "active_directory" {
  name              = "/aws/directoryservice/${aws_directory_service_directory.active_directory.id}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "ad-log-policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    principals {
      identifiers = ["ds.amazonaws.com"]
      type        = "Service"
    }

    resources = ["${aws_cloudwatch_log_group.active_directory.arn}:*"]

    effect = "Allow"
  }
}

resource "aws_cloudwatch_log_resource_policy" "active_directory-log-policy" {
  policy_document = data.aws_iam_policy_document.ad-log-policy.json
  policy_name     = "ad-log-policy-${local.application_name}-${local.environment}"
}

resource "aws_directory_service_log_subscription" "active_directory" {
  directory_id   = aws_directory_service_directory.active_directory.id
  log_group_name = aws_cloudwatch_log_group.active_directory.name
  depends_on = [
    aws_cloudwatch_log_resource_policy.active_directory-log-policy
  ]
}

##
#  Create Route53 Resolve endpoint, rule and security group to ensure that requests to domain FQDN are forwarded to the DCs
##
resource "aws_security_group" "iaps_ad_dns_resolver_security_group" {
  provider = aws.core-vpc

  name        = "DNS resolver for ${local.domain_full_name}"
  description = "Security Group for DNS resolver requests relating to ${local.domain_full_name}"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "iaps_ad_dns_resolver_security_group_rule_egress" {
  provider = aws.core-vpc

  for_each          = local.application_data.dns_endpoint_egress_rules
  description       = format("VPC to DNS Endpoint traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.iaps_ad_dns_resolver_security_group.id
  to_port           = each.value.to_port
  type              = "egress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}
resource "aws_route53_resolver_endpoint" "resolve_local_entries_using_ad_dns" {
  provider = aws.core-vpc

  name      = replace(local.domain_full_name, ".", "-")
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.iaps_ad_dns_resolver_security_group.id
  ]
  dynamic "ip_address" {
    for_each = data.aws_subnets.shared-private.ids
    content {
      subnet_id = ip_address.value
    }
  }

  # Removing tags temporarily due to identity-based policy permission error
  # tags = {
  #   Name = "${replace(local.domain_full_name, ".", "-")}"
  # }
}

resource "aws_route53_resolver_rule" "r53_fwd_to_ad" {
  provider = aws.core-vpc

  domain_name = local.domain_full_name
  name        = replace(local.domain_full_name, ".", "-")
  rule_type   = "FORWARD"

  resolver_endpoint_id = aws_route53_resolver_endpoint.resolve_local_entries_using_ad_dns.id

  dynamic "target_ip" {
    for_each = local.domain_dns_ips
    content {
      ip = target_ip.value
    }
  }

  # Removing tags temporarily due to identity-based policy permission error
  # tags = {
  #   Name = "${replace(local.domain_full_name, ".", "-")}"
  # }
}

resource "aws_route53_resolver_rule_association" "vpc_r53_fwd_to_ad" {
  provider = aws.core-vpc

  resolver_rule_id = aws_route53_resolver_rule.r53_fwd_to_ad.id
  vpc_id           = data.aws_vpc.shared.id
}
