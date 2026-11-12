# Allow HTTPS out of the mwaa namespace so pods can reach AWS APIs (STS, S3, Glue, Athena, Secrets Manager).
# NetworkPolicies are additive, so default-deny still applies to everything else.
resource "kubernetes_network_policy_v1" "mwaa_allow_egress_https" {
  metadata {
    name      = "mwaa-allow-egress-https"
    namespace = kubernetes_namespace_v1.mwaa.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      to {
        ip_block {
          cidr   = "0.0.0.0/0"
          except = ["169.254.169.254/32"] # keep IMDS blocked; pods use IRSA
        }
      }
      ports {
        protocol = "TCP"
        port     = "443"
      }
    }
  }
}
