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

###
# AD Join - Provide SG that EC2s can use if they need to join domain
###

resource "aws_security_group" "mis_ad_join" {
  #checkov:skip=CKV2_AWS_5 "ignore"
  name        = "${var.env_name}-mis-ad-join-sg"
  description = "Security Group allowing Computers to join domain"
  vpc_id      = var.account_info.vpc_id

  tags = merge(var.tags, {
    Name = "${var.env_name}-mis-ad-join-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "mis_ad_join" {
  for_each = {
    icmp-from-dc             = { ip_protocol = "ICMP", from_port = 8, to_port = 0 }
    rpc-from-dc              = { ip_protocol = "TCP", port = 135 }
    rpc-tcp-dynamic2-from-dc = { ip_protocol = "TCP", from_port = 49152, to_port = 65535 }
  }

  description       = each.key
  security_group_id = resource.aws_security_group.mis_ad_join.id

  ip_protocol                  = lookup(each.value, "ip_protocol", "-1")
  from_port                    = lookup(each.value, "port", lookup(each.value, "from_port", null))
  to_port                      = lookup(each.value, "port", lookup(each.value, "to_port", null))
  referenced_security_group_id = aws_directory_service_directory.mis_ad.security_group_id

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "mis_ad_join" {
  description       = "Allow all egress to DC"
  security_group_id = resource.aws_security_group.mis_ad_join.id

  ip_protocol                  = "-1"
  referenced_security_group_id = aws_directory_service_directory.mis_ad.security_group_id

  tags = var.tags
}
