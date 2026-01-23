resource "aws_networkfirewall_firewall" "main" {
  name                = "${local.application_name}-${local.environment}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.strict.arn
  vpc_id              = aws_vpc.main.id

  delete_protection                 = true
  firewall_policy_change_protection = true
  subnet_change_protection          = true

  enabled_analysis_types = ["HTTP_HOST", "TLS_SNI"]

  encryption_configuration {
    type   = "CUSTOMER_KMS"
    key_id = module.network_firewall_kms_key.key_arn
  }

  dynamic "subnet_mapping" {
    for_each = {
      "firewall-a" = aws_subnet.main["firewall-a"]
      "firewall-b" = aws_subnet.main["firewall-b"]
      "firewall-c" = aws_subnet.main["firewall-c"]
    }

    content {
      subnet_id = subnet_mapping.value.id
    }
  }
}

resource "aws_networkfirewall_logging_configuration" "cloudwatch" {
  firewall_arn                = aws_networkfirewall_firewall.main.arn
  enable_monitoring_dashboard = true

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = module.network_firewall_flow_log_group.cloudwatch_log_group_name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
    log_destination_config {
      log_destination = {
        logGroup = module.network_firewall_alerts_log_group.cloudwatch_log_group_name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}

resource "aws_networkfirewall_firewall_policy" "strict" {
  name = "strict"

  encryption_configuration {
    type   = "CUSTOMER_KMS"
    key_id = module.network_firewall_kms_key.key_arn
  }

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:drop"]

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    # Recommended for STRICT_ORDER so TCP can establish and app-layer rules can match
    stateful_default_actions = [
      "aws:drop_established",
      "aws:alert_established",
    ]

    stateful_rule_group_reference {
      priority     = 1
      resource_arn = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/AttackInfrastructureStrictOrder"
    }

    stateful_rule_group_reference {
      priority     = 2
      resource_arn = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/BotNetCommandAndControlDomainsStrictOrder"
    }

    stateful_rule_group_reference {
      priority     = 3
      resource_arn = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/MalwareDomainsStrictOrder"
    }

    # 1) IP allowlist (TCP/UDP/ICMP)
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.strict_ip.arn
      priority     = 10
    }

    # 2) FQDN allowlist (HTTP host + TLS SNI)
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.strict_fqdn.arn
      priority     = 20
    }
  }
}

resource "aws_networkfirewall_rule_group" "strict_ip" {
  name     = "strict-ip"
  type     = "STATEFUL"
  capacity = 10000

  encryption_configuration {
    type   = "CUSTOMER_KMS"
    key_id = module.network_firewall_kms_key.key_arn
  }

  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [local.network_configuration.vpc.cidr_block]
        }
      }
      ip_sets {
        key = "GITHUB_GIT"
        ip_set {
          definition = jsondecode(data.http.github_meta.response_body)["git"]
        }
      }
    }

    rules_source {
      rules_string = templatefile("src/templates/network-firewall/ip.rules.tftpl", { rules = local.network_firewall_rules.ip.rules })
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }
}

resource "aws_networkfirewall_rule_group" "strict_fqdn" {
  name     = "strict-fqdn"
  type     = "STATEFUL"
  capacity = 3000

  encryption_configuration {
    type   = "CUSTOMER_KMS"
    key_id = module.network_firewall_kms_key.key_arn
  }

  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [local.network_configuration.vpc.cidr_block]
        }
      }
    }

    rules_source {
      rules_string = templatefile("src/templates/network-firewall/fqdn.rules.tftpl", { rules = local.network_firewall_rules.fqdn.rules })
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }
}
