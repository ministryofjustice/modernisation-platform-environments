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
