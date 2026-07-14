###############################################################################
# ArgoCD GitOps — AppProjects and ApplicationSets (ADR-002, ADR-015, US-015b)
#
# Deploys ArgoCD control plane resources (Level 1) on the hub cluster:
# - Per-BU AppProjects with sourceRepos and destination restrictions
# - Platform AppProject for infrastructure add-ons
# - Per-BU ApplicationSets using git-directory-generator
#
# Only created when the cluster has the argocd-role=hub tag (set by the
# cluster component when enable_argocd=true).
#
# References:
#   - ADR-002: AppProject Hierarchy and BU Isolation Guardrails
#   - ADR-015: Per-BU Workload Repos with Shared Platform Config Repo
#   - US-015b: Spoke Registration and GitOps Configuration
###############################################################################

locals {
  # Detect if this cluster is an ArgoCD hub by checking the cluster tag
  is_argocd_hub = lookup(data.aws_eks_cluster.cluster.tags, "argocd-role", "") == "hub"

  # BU configuration — defines the spoke clusters and their source repos
  # Each BU gets a nonlive and live AppProject + ApplicationSet pair
  bu_configs = {
    octo = {
      source_repo = "https://github.com/ministryofjustice/container-platform-environments"
      clusters = {
        nonlive = "container-platform-octo-nonlive"
        live    = "container-platform-octo-live"
      }
    }
    laa = {
      source_repo = "https://github.com/ministryofjustice/container-platform-laa"
      clusters = {
        nonlive = "container-platform-laa-nonlive"
        live    = "container-platform-laa-live"
      }
    }
    hmpps = {
      source_repo = "https://github.com/ministryofjustice/container-platform-hmpps"
      clusters = {
        nonlive = "container-platform-hmpps-nonlive"
        live    = "container-platform-hmpps-live"
      }
    }
  }

  # Flatten BU configs into per-environment AppProject entries
  bu_appprojects = merge([
    for bu_name, bu_config in local.bu_configs : {
      for env, cluster_workspace in bu_config.clusters :
      "${bu_name}-${env}" => {
        bu_name           = bu_name
        environment       = env
        source_repo       = bu_config.source_repo
        cluster_workspace = cluster_workspace
        # Cluster ARN constructed from account ID + cluster name
        cluster_arn = "arn:aws:eks:eu-west-2:${local.environment_management.account_ids[cluster_workspace]}:cluster/${element(reverse(split("-", cluster_workspace)), 0)}"
        auto_sync   = env == "nonlive" ? true : false
      }
    }
  ]...)

  # GitHub org base URL for sourceRepos patterns
  github_org = "https://github.com/ministryofjustice"
}

#------------------------------------------------------------------------------
# Platform AppProject — deploys infrastructure add-ons to all spoke clusters
#------------------------------------------------------------------------------
resource "kubectl_manifest" "argocd_project_platform_nonlive" {
  count = local.is_argocd_hub ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "platform-nonlive"
      namespace = "argocd"
    }
    spec = {
      description = "Platform infrastructure add-ons deployed to all non-live spoke clusters"
      sourceRepos = [
        "${local.github_org}/container-platform-config",
        "${local.github_org}/container-platform-config.git",
      ]
      destinations = [
        for bu_name, bu_config in local.bu_configs : {
          server    = local.bu_appprojects["${bu_name}-nonlive"].cluster_arn
          namespace = "*"
        }
      ]
      clusterResourceWhitelist = [
        { group = "*", kind = "Namespace" },
        { group = "rbac.authorization.k8s.io", kind = "ClusterRole" },
        { group = "rbac.authorization.k8s.io", kind = "ClusterRoleBinding" },
        { group = "admissionregistration.k8s.io", kind = "*" },
        { group = "apiextensions.k8s.io", kind = "CustomResourceDefinition" },
      ]
      namespaceResourceWhitelist = [
        { group = "*", kind = "*" }
      ]
    }
  })
}

resource "kubectl_manifest" "argocd_project_platform_live" {
  count = local.is_argocd_hub ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "platform-live"
      namespace = "argocd"
    }
    spec = {
      description = "Platform infrastructure add-ons deployed to all live spoke clusters"
      sourceRepos = [
        "${local.github_org}/container-platform-config",
        "${local.github_org}/container-platform-config.git",
      ]
      destinations = [
        for bu_name, bu_config in local.bu_configs : {
          server    = local.bu_appprojects["${bu_name}-live"].cluster_arn
          namespace = "*"
        }
      ]
      clusterResourceWhitelist = [
        { group = "*", kind = "Namespace" },
        { group = "rbac.authorization.k8s.io", kind = "ClusterRole" },
        { group = "rbac.authorization.k8s.io", kind = "ClusterRoleBinding" },
        { group = "admissionregistration.k8s.io", kind = "*" },
        { group = "apiextensions.k8s.io", kind = "CustomResourceDefinition" },
      ]
      namespaceResourceWhitelist = [
        { group = "*", kind = "*" }
      ]
    }
  })
}


#------------------------------------------------------------------------------
# Per-BU AppProjects — isolates each BU's workloads to their own cluster and repos
#------------------------------------------------------------------------------
resource "kubectl_manifest" "argocd_project_bu" {
  for_each = local.is_argocd_hub ? local.bu_appprojects : {}

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = each.key
      namespace = "argocd"
      labels = {
        "argocd.argoproj.io/managed-by"  = "terraform"
        "container-platform/bu"          = each.value.bu_name
        "container-platform/environment" = each.value.environment
      }
    }
    spec = {
      description = "Workload deployments for ${upper(each.value.bu_name)} ${each.value.environment}"
      sourceRepos = [
        each.value.source_repo,
        "${each.value.source_repo}.git",
      ]
      destinations = [
        {
          server    = each.value.cluster_arn
          namespace = "*"
        }
      ]
      # BU workload projects can only create workload-level resources
      namespaceResourceWhitelist = [
        { group = "", kind = "ConfigMap" },
        { group = "", kind = "Secret" },
        { group = "", kind = "Service" },
        { group = "", kind = "ServiceAccount" },
        { group = "", kind = "PersistentVolumeClaim" },
        { group = "apps", kind = "Deployment" },
        { group = "apps", kind = "StatefulSet" },
        { group = "apps", kind = "DaemonSet" },
        { group = "apps", kind = "ReplicaSet" },
        { group = "batch", kind = "Job" },
        { group = "batch", kind = "CronJob" },
        { group = "autoscaling", kind = "HorizontalPodAutoscaler" },
        { group = "policy", kind = "PodDisruptionBudget" },
        { group = "networking.k8s.io", kind = "Ingress" },
        { group = "networking.k8s.io", kind = "NetworkPolicy" },
        { group = "gateway.networking.k8s.io", kind = "HTTPRoute" },
        { group = "gateway.networking.k8s.io", kind = "GRPCRoute" },
      ]
      # BU projects cannot create cluster-scoped resources
      clusterResourceBlacklist = [
        { group = "*", kind = "Namespace" },
        { group = "rbac.authorization.k8s.io", kind = "ClusterRole" },
        { group = "rbac.authorization.k8s.io", kind = "ClusterRoleBinding" },
        { group = "apiextensions.k8s.io", kind = "CustomResourceDefinition" },
      ]
    }
  })
}


#------------------------------------------------------------------------------
# Per-BU ApplicationSets — git-directory-generator creates Applications
# automatically when new app directories appear in the BU repo
#------------------------------------------------------------------------------
resource "kubectl_manifest" "argocd_applicationset_bu" {
  for_each = local.is_argocd_hub ? local.bu_appprojects : {}

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "${each.key}-apps"
      namespace = "argocd"
      labels = {
        "argocd.argoproj.io/managed-by"  = "terraform"
        "container-platform/bu"          = each.value.bu_name
        "container-platform/environment" = each.value.environment
      }
    }
    spec = {
      goTemplate        = true
      goTemplateOptions = ["missingkey=error"]
      generators = [
        {
          git = {
            repoURL  = each.value.source_repo
            revision = "main"
            directories = [
              { path = "*/deployment/${each.value.environment}" }
            ]
          }
        }
      ]
      template = {
        metadata = {
          name = "${each.value.bu_name}-{{ index .path.segments 0 }}-${each.value.environment}"
          labels = {
            "container-platform/bu"          = each.value.bu_name
            "container-platform/environment" = each.value.environment
            "container-platform/app"         = "{{ index .path.segments 0 }}"
          }
        }
        spec = {
          project = each.key
          source = {
            repoURL        = each.value.source_repo
            targetRevision = "main"
            path           = "{{ .path.path }}"
          }
          destination = {
            server    = each.value.cluster_arn
            namespace = "{{ index .path.segments 0 }}"
          }
          syncPolicy = each.value.auto_sync ? {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = [
              "CreateNamespace=true",
              "PrunePropagationPolicy=foreground",
            ]
            } : {
            automated = null
            syncOptions = [
              "CreateNamespace=true",
            ]
          }
        }
      }
    }
  })

  depends_on = [kubectl_manifest.argocd_project_bu]
}
