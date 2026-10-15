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
