locals {
  kyverno_privileged_policy_manifests = {
    for policy in local.kyverno_privileged_policies : policy.name => {
      apiVersion = "kyverno.io/v1"
      kind       = "ClusterPolicy"
      metadata = {
        name = "enforce-${policy.name}-privileged"
      }
      spec = {
        rules = [
          {
            name = "set-capabilities"
            match = {
              resources = {
                kinds      = ["Pod"]
                namespaces = policy.namespaces
                selector = {
                  matchLabels = policy.pod_selector_labels
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
                          add  = policy.capabilities_add
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
                          add  = policy.capabilities_add
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
  }
}

resource "helm_release" "kyverno_privileged_policy" {
  name      = "kyverno-privileged-policies"
  chart     = "./src/helm/charts/manifests"
  namespace = module.kyverno_namespace.name

  values = [yamlencode({ manifests = local.kyverno_privileged_policy_manifests })]

  depends_on = [helm_release.kyverno]
}

# ── Network policies ─────────────────────────────────────────────────────────
# Kyverno's default-deny NetworkPolicy (generate-default-network-policy) blocks
# all egress except DNS. Namespaces listed below additionally get HTTPS egress
# so pods can reach AWS APIs (STS, S3, Glue, Athena, Secrets Manager).
# NetworkPolicies are additive, so default-deny still applies to everything else.

locals {
  kyverno_allow_egress_https_namespaces = ["mwaa"]

  kyverno_network_policy_manifests = {
    allow-egress-https = {
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
        generateExisting = true # also apply to namespaces that already exist
        rules = [
          {
            name = "allow-egress-https"
            match = {
              any = [
                {
                  resources = {
                    kinds = ["Namespace"]
                    names = local.kyverno_allow_egress_https_namespaces
                  }
                }
              ]
            }
            generate = {
              synchronize = true # recreate if deleted, update if changed
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
                            except = ["169.254.169.254/32"] # keep IMDS blocked; pods use IRSA
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
  }
}

resource "helm_release" "kyverno_network_policies" {
  name      = "kyverno-network-policies"
  chart     = "./src/helm/charts/manifests"
  namespace = module.kyverno_namespace.name

  values = [yamlencode({ manifests = local.kyverno_network_policy_manifests })]

  depends_on = [helm_release.kyverno]
}
