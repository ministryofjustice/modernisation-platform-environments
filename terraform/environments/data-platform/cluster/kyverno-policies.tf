resource "kubernetes_manifest" "kyverno_privileged_policy" {
  for_each = { for policy in local.kyverno_privileged_policies : policy.name => policy }
  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "enforce-${each.value.name}-privileged"
    }
    spec = {
      rules = [
        {
          name = "set-capabilities"
          match = {
            resources = {
              kinds      = ["Pod"]
              namespaces = each.value.namespaces
              selector = {
                matchLabels = each.value.pod_selector_labels
              }
            }
          }
          mutate = {
            patchStrategicMerge = {
              spec = {
                containers = [
                  {
                    "(name)" = "*"
                    securityContext = {
                      privileged             = false
                      readOnlyRootFilesystem = false
                      seLinuxOptions = {
                        level = "s0"
                        role  = "system_r"
                        type  = "super_t"
                        user  = "system_u"
                      }
                      capabilities = {
                        drop = ["ALL"]
                        add  = each.value.capabilities_add
                      }
                    }
                  }
                ]
                initContainers = [
                  {
                    "(name)" = "*"
                    securityContext = {
                      privileged             = false
                      readOnlyRootFilesystem = false
                      seLinuxOptions = {
                        level = "s0"
                        role  = "system_r"
                        type  = "super_t"
                        user  = "system_u"
                      }
                      capabilities = {
                        drop = ["ALL"]
                        add  = each.value.capabilities_add
                      }
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
  depends_on = [helm_release.kyverno]
}

# Kyverno's default-deny NetworkPolicy (generate-default-network-policy) blocks
# all egress except DNS. Allow HTTPS out of the MWAA namespace so pods can reach
# AWS APIs (STS, S3, Glue, Athena, Secrets Manager). IMDS stays blocked.
resource "kubernetes_manifest" "kyverno_allow_egress_https" {
  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "generate-allow-egress-https"
      annotations = {
        "policies.kyverno.io/title"       = "Generate Allow Egress HTTPS NetworkPolicy"
        "policies.kyverno.io/description" = "default-deny blocks all egress except DNS. Allow HTTPS out so pods can reach AWS APIs."
      }
    }
    spec = {
      generateExisting = true
      rules = [
        {
          name = "allow-egress-https"
          match = {
            any = [
              {
                resources = {
                  kinds = ["Namespace"]
                  names = ["mwaa"]
                }
              }
            ]
          }
          generate = {
            synchronize = true
            apiVersion  = "networking.k8s.io/v1"
            kind        = "NetworkPolicy"
            name        = "allow-egress-https"
            namespace   = "{{request.object.metadata.name}}"
            data = {
              spec = {
                podSelector = {}
                policyTypes = ["Egress"]
                egress = [
                  {
                    to = [
                      {
                        ipBlock = {
                          cidr   = "0.0.0.0/0"
                          except = ["169.254.169.254/32"]
                        }
                      }
                    ]
                    ports = [
                      { protocol = "TCP", port = 443 }
                    ]
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }

  depends_on = [helm_release.kyverno]
}
