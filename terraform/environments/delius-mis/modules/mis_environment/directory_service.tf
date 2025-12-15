locals {
  domain_full_name = "${var.app_name}-${var.env_name}.internal"
}

resource "aws_directory_service_directory" "mis_ad" {
  name = local.domain_full_name

  description = "Microsoft AD for ${var.app_name}-${var.env_name}"

  type    = "MicrosoftAD"
  edition = "Standard"

  password = data.aws_secretsmanager_secret_version.ad_admin_password.secret_string

  vpc_settings {
    vpc_id     = var.account_info.vpc_id
    subnet_ids = slice(var.account_config.private_subnet_ids, 0, 2)
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      password
    ]
  }
}

resource "aws_secretsmanager_secret" "ad_admin_password" {
  name                    = "${var.app_name}-${var.env_name}-ad-admin-password"
  recovery_window_in_days = 0

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-${var.env_name}-ad-admin-password"
    }
  )
}

data "aws_secretsmanager_secret_version" "ad_admin_password" {
  secret_id = aws_secretsmanager_secret.ad_admin_password.id
}

###
# Logging
###

resource "aws_cloudwatch_log_group" "active_directory" {
  name              = "/aws/directoryservice/${aws_directory_service_directory.mis_ad.id}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "ad_log_policy" {
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

resource "aws_cloudwatch_log_resource_policy" "active_directory_log_policy" {
  policy_document = data.aws_iam_policy_document.ad_log_policy.json
  policy_name     = "ad-log-policy-${var.app_name}-${var.env_name}"
}

resource "aws_directory_service_log_subscription" "active_directory" {
  directory_id   = aws_directory_service_directory.mis_ad.id
  log_group_name = aws_cloudwatch_log_group.active_directory.name
  depends_on = [
    aws_cloudwatch_log_resource_policy.active_directory_log_policy
  ]
}

###
# Administration EC2 instance
# - Creation of instance is click-ops but we can manage the SG in code
###

resource "aws_security_group" "mis_ad_management" {
  name        = "${var.env_name}-ad-management"
  description = "Security Group for Directory Service Management Instance"
  vpc_id      = var.account_info.vpc_id
}

resource "aws_vpc_security_group_engress_rule" "mis_ad_management" {
  # equivalent of AmazonSSMDirectoryServiceSecurityGroup default rule
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all egress"
  ip_protocol       = -1
  security_group_id = aws_security_group.mis_ad_management.id
  tags              = var.tags
}

###
# Route 53 Resolver setup
###

resource "aws_security_group" "mis_ad_dns_resolver_security_group" {
  provider = aws.core-vpc

  name        = "DNS resolver for ${local.domain_full_name}"
  description = "Security Group for DNS resolver requests relating to ${local.domain_full_name}"
  vpc_id      = var.account_config.shared_vpc_id
}

resource "aws_security_group_rule" "mis_ad_dns_resolver_security_group_rule_egress" {
  provider = aws.core-vpc

  for_each = {
    tcp = "tcp"
    udp = "udp"
  }
  description       = "VPC to DNS Endpoint traffic for (${each.key})"
  from_port         = 53
  protocol          = each.value
  security_group_id = aws_security_group.mis_ad_dns_resolver_security_group.id
  to_port           = 53
  type              = "egress"
  cidr_blocks       = [var.account_config.shared_vpc_cidr]
}

resource "aws_route53_resolver_endpoint" "resolve_local_entries_using_ad_dns" {
  provider = aws.core-vpc

  name      = replace(local.domain_full_name, ".", "-")
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.mis_ad_dns_resolver_security_group.id
  ]
  dynamic "ip_address" {
    for_each = var.account_config.private_subnet_ids
    content {
      subnet_id = ip_address.value
    }
  }
}

resource "aws_route53_resolver_rule" "r53_fwd_to_ad" {
  provider = aws.core-vpc

  domain_name = local.domain_full_name
  name        = replace(local.domain_full_name, ".", "-")
  rule_type   = "FORWARD"

  resolver_endpoint_id = aws_route53_resolver_endpoint.resolve_local_entries_using_ad_dns.id

  dynamic "target_ip" {
    for_each = sort(aws_directory_service_directory.mis_ad.dns_ip_addresses)
    content {
      ip = target_ip.value
    }
  }
}

resource "aws_route53_resolver_rule_association" "vpc_r53_fwd_to_ad" {
  provider = aws.core-vpc

  resolver_rule_id = aws_route53_resolver_rule.r53_fwd_to_ad.id
  vpc_id           = var.account_config.shared_vpc_id
}
