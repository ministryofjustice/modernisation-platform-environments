###############################################################################
# WAF source-IP allowlist for the test workload
#
# Filters inbound traffic at the shared ALB before it reaches the cluster.
# Independent of the cluster's CNI / EKS Auto Mode status, since WAF evaluates
# at the AWS networking layer in front of the load balancer.
###############################################################################

locals {
  echo_hostnames = {
    for i in range(1, 5) :
    "echo${i}" => "echo${i}.${local.cluster_name}.${local.cluster_base_domain}"
  }

  # Scenario 9: hostnames routed via the second Gateway (shared-alb-b).
  # Kept separate from echo_hostnames so the per-Gateway split is explicit.
  echo_b_hostnames = {
    "echo5" = "echo5.${local.cluster_name}.${local.cluster_base_domain}"
  }
}

resource "aws_wafv2_ip_set" "echo_allowlist" {
  name               = "${local.cluster_name}-echo-source-ip-allowlist"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["83.100.215.187/32"]
}

resource "aws_wafv2_ip_set" "echo3_allowlist" {
  name               = "${local.cluster_name}-echo3-source-ip-allowlist"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["203.0.113.1/32"]
}

resource "aws_wafv2_ip_set" "echo4_allowlist" {
  name               = "${local.cluster_name}-echo4-source-ip-allowlist"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["203.0.113.1/32"]
}

resource "aws_wafv2_web_acl" "echo" {
  name  = "${local.cluster_name}-echo-source-ip-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "restrict-echo1-to-allowlist"
    priority = 1

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          byte_match_statement {
            search_string         = local.echo_hostnames["echo1"]
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
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.echo_allowlist.arn
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "echo1-source-ip-restrict"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "restrict-echo3-to-allowlist"
    priority = 2

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          byte_match_statement {
            search_string         = local.echo_hostnames["echo3"]
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
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.echo3_allowlist.arn
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "echo3-source-ip-restrict"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "restrict-echo4-misconfigured"
    priority = 3

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          byte_match_statement {
            search_string         = "echo4"
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
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.echo4_allowlist.arn
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "echo4-source-ip-restrict"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.cluster_name}-echo-source-ip-acl"
    sampled_requests_enabled   = true
  }
}

# Look up the ALB that AWS LBC provisioned for the shared-alb Gateway.
# Filter on the gateway-stack tag (namespace/name) to disambiguate from any
# other ALBs the controller may provision in the same cluster (scenario 9).
data "aws_lb" "shared_alb" {
  tags = {
    "elbv2.k8s.aws/cluster"        = local.cluster_name
    "gateway.k8s.aws.alb/stack"    = "lbc-test/shared-alb"
  }

  depends_on = [
    kubectl_manifest.gateway_platform,
    kubernetes_manifest.user_test_http_routes,
  ]
}

resource "aws_wafv2_web_acl_association" "echo" {
  resource_arn = data.aws_lb.shared_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.echo.arn
}

###############################################################################
# Scenario 9: second Web ACL for the second Gateway (shared-alb-b)
#
# Demonstrates that two Gateways on the same cluster, each with its own ALB and
# its own Web ACL, coexist without interference. echo5 lives behind Gateway B
# only; ACL B has one rule for echo5 and knows nothing about echo1-4.
###############################################################################

resource "aws_wafv2_ip_set" "echo5_allowlist" {
  name               = "${local.cluster_name}-echo5-source-ip-allowlist"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["83.100.215.187/32"]
}

resource "aws_wafv2_web_acl" "echo_b" {
  name  = "${local.cluster_name}-echo-b-source-ip-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "restrict-echo5-to-allowlist"
    priority = 1

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          byte_match_statement {
            search_string         = local.echo_b_hostnames["echo5"]
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
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.echo5_allowlist.arn
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "echo5-source-ip-restrict"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.cluster_name}-echo-b-source-ip-acl"
    sampled_requests_enabled   = true
  }
}

data "aws_lb" "shared_alb_b" {
  tags = {
    "elbv2.k8s.aws/cluster"     = local.cluster_name
    "gateway.k8s.aws.alb/stack" = "lbc-test/shared-alb-b"
  }

  depends_on = [
    kubectl_manifest.gateway_b,
    kubernetes_manifest.user_test_http_routes_b,
  ]
}

resource "aws_wafv2_web_acl_association" "echo_b" {
  resource_arn = data.aws_lb.shared_alb_b.arn
  web_acl_arn  = aws_wafv2_web_acl.echo_b.arn
}
