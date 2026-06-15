###############################################################################
# Deny-by-default WAF for the shared ALB.
#
# Inversion of the opt-in model (source-ip-restriction branch). Instead of
# default-ALLOW with per-host block rules, this is default-BLOCK with per-host
# ALLOW rules:
#
#   default_action = block
#   per host:  (Host == hostname) AND (src_ip IN host_allowlist)  -> allow
#
# A workload's hostname reaches the cluster only if an allow rule exists for it
# AND the source IP is in that host's allowlist. Everything else falls through
# to the default block. A hostname with no allow rule is denied outright.
#
# Allowlist content is restricted to internal network sources per the ticket
# scope; the test CIDRs here stand in for that catalogue during the POC.
###############################################################################

locals {
  # Per-host allowlists, keyed by short name.
  #
  # EMPTY for D4 (default-block, zero allow rules) to prove the defining
  # property: with no rule present, the host is denied. Later steps populate
  # this map; each entry has:
  #   hostname = the exact Host header to match
  #   cidrs    = allowed source CIDRs (internal network sources)
  #   priority = WAF rule priority (unique per rule)
  deny_allowlists = {
    echo1 = {
      hostname = "echo1.${local.cluster_name}.${local.cluster_base_domain}"
      cidrs    = ["83.100.215.187/32"]
      priority = 1
    }
    # D2: echo3 gets its own rule + IP set with a DIFFERENT (dummy) CIDR. From
    # the test source IP this must yield echo1 -> 200 and echo3 -> 403
    # simultaneously, proving per-host rules are independent (no cross-bleed).
    echo3 = {
      hostname = "echo3.${local.cluster_name}.${local.cluster_base_domain}"
      cidrs    = ["203.0.113.3/32"]
      priority = 2
    }
  }
}

# The LBC-provisioned ALB for the shared-alb Gateway (Tim's foundation).
# Identified by the Gateway API stack tag the controller applies.
data "aws_lb" "deny_shared_alb" {
  tags = {
    "elbv2.k8s.aws/cluster"     = local.cluster_name
    "gateway.k8s.aws.alb/stack" = "lbc-test/shared-alb"
  }
}

resource "aws_wafv2_ip_set" "deny_allowlist" {
  for_each = local.deny_allowlists

  name               = "${local.cluster_name}-${each.key}-deny-allowlist"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = each.value.cidrs
}

resource "aws_wafv2_web_acl" "deny_shared_alb" {
  name        = "${local.cluster_name}-deny-shared-alb"
  description = "Deny-by-default for shared-alb: default action block, per-host allow rules."
  scope       = "REGIONAL"

  default_action {
    block {}
  }

  # One allow rule per host in deny_allowlists. No entries -> no rules -> every
  # request hits the default block (D4).
  dynamic "rule" {
    for_each = local.deny_allowlists

    content {
      name     = "allow-${rule.key}"
      priority = rule.value.priority

      action {
        allow {}
      }

      statement {
        and_statement {
          statement {
            byte_match_statement {
              search_string         = rule.value.hostname
              positional_constraint = "EXACTLY"

              field_to_match {
                single_header {
                  name = "host"
                }
              }

              text_transformation {
                priority = 0
                type     = "LOWERCASE"
              }
            }
          }

          statement {
            ip_set_reference_statement {
              arn = aws_wafv2_ip_set.deny_allowlist[rule.key].arn
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "allow-${rule.key}"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.cluster_name}-deny-shared-alb"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "deny_shared_alb" {
  resource_arn = data.aws_lb.deny_shared_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.deny_shared_alb.arn
}
