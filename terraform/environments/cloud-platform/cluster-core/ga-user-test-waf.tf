###############################################################################
# WAF source-IP allowlist for the test workload
#
# Filters inbound traffic at the shared ALB before it reaches the cluster.
# Independent of the cluster's CNI / EKS Auto Mode status, since WAF evaluates
# at the AWS networking layer in front of the load balancer.
###############################################################################

resource "aws_wafv2_ip_set" "echo_allowlist" {
  name               = "${local.cluster_name}-echo-source-ip-allowlist"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["83.100.215.187/32"]
}

resource "aws_wafv2_web_acl" "echo" {
  name  = "${local.cluster_name}-echo-source-ip-acl"
  scope = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "allow-from-allowlist"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.echo_allowlist.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "echo-source-ip-allow"
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
data "aws_lb" "shared_alb" {
  tags = {
    "elbv2.k8s.aws/cluster" = local.cluster_name
  }

  depends_on = [
    kubectl_manifest.gateway_platform,
    kubernetes_manifest.user_test_http_route,
  ]
}

resource "aws_wafv2_web_acl_association" "echo" {
  resource_arn = data.aws_lb.shared_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.echo.arn
}
