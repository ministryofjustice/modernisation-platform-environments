###############################################################################
# ArgoCD GitOps — AppProjects and ApplicationSets (ADR-002, ADR-015, US-015b)
#
# Deploys ArgoCD control plane resources (Level 1) on the hub cluster:
# - Per-BU AppProjects with sourceRepos and destination restrictions
# - Platform AppProject for infrastructure add-ons and namespace baselines
# - Per-BU ApplicationSets using git-directory-generator (workloads)
# - Per-BU baseline ApplicationSets using git-file-generator (product.yaml)
#
# Only created when the cluster has the argocd-role=hub tag (set by the
# cluster component when enable_argocd=true).
#
# References:
#   - ADR-002: AppProject Hierarchy and BU Isolation Guardrails
#   - ADR-015: Shared Monorepo with Product-Based Structure (amended)
#   - US-015b: Spoke Registration and GitOps Configuration
#   - product-onboarding-tier2-design.md: Tier 2 design document
###############################################################################

locals {
  # Detect if this cluster is an ArgoCD hub by checking the cluster tag
  is_argocd_hub = lookup(data.aws_eks_cluster.cluster.tags, "argocd-role", "") == "hub"

  # Shared monorepo for all BU workload manifests and baseline chart.
  #
  # The EKS-managed Argo CD capability runs in AWS-managed infrastructure and
  # cannot reach github.com directly — it clones repositories through the
  # CodeConnections git-http proxy.
  #
  # Proxy URL format (see AWS docs — "Connect to Git repositories with AWS
  # CodeConnections"):
  #   https://codeconnections.<region>.amazonaws.com/git-http/<account-id>/<region>/<connection-id>/<org>/<repo>
  environments_repo_org  = "ministryofjustice"
  environments_repo_name = "container-platform-environments"

  # Connection ID is the last path segment of the CodeConnection ARN
  # (arn:aws:codeconnections:<region>:<account>:connection/<connection-id>)
  argocd_codeconnection_id = element(reverse(split("/", local.argocd_codeconnection_arn)), 0)

  environments_repo = "https://codeconnections.${data.aws_region.current.region}.amazonaws.com/git-http/${data.aws_caller_identity.current.account_id}/${data.aws_region.current.region}/${local.argocd_codeconnection_id}/${local.environments_repo_org}/${local.environments_repo_name}.git"

  # BU configuration — defines the spoke clusters and path within the monorepo
  # Each BU gets a nonlive and live AppProject + ApplicationSet pair
  # All BUs share the same source repo; isolation is via path prefix + AppProject destinations
  bu_configs = {
    octo = {
      clusters = {
        nonlive = "container-platform-octo-nonlive"
        live    = "container-platform-octo-live"
      }
    }
    laa = {
      clusters = {
        nonlive = "container-platform-laa-nonlive"
        live    = "container-platform-laa-live"
      }
    }
    hmpps = {
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
        source_repo       = local.environments_repo
        cluster_workspace = cluster_workspace
        # Path prefix within monorepo for this BU's products
        path_prefix = "namespaces/${bu_name}"
        # Cluster ARN constructed from account ID + cluster name
        cluster_arn = "arn:aws:eks:eu-west-2:${local.environment_management.account_ids[cluster_workspace]}:cluster/${cluster_workspace}"
        auto_sync   = env == "nonlive" ? true : false
      }
    }
  ]...)

  #-----------------------------------------------------------------------------
  # Hub tier scoping (ADR-002 — dual-hub isolation)
  #
  # A hub must only register the spokes it owns: the nonlive hub manages nonlive
  # spokes, the live hub manages live spokes. Without this, every hub creates
  # ArgoCD control-plane objects (AppProjects, ApplicationSets and — critically
  # — cluster registration Secrets) for the OTHER tier's spokes, breaking tier
  # isolation.
  #
  # Permanent hubs derive their tier from the workspace name (last segment,
  # computed as local.workspace_environment: "nonlive" or "live"). Ephemeral
  # dev hubs (cluster_environment == "development_cluster") are not a permanent
  # tier and must NOT register any real BU spoke — they register only their
  # convention-paired spoke, "<hub-workspace-minus-hub-suffix>spoke".
  #-----------------------------------------------------------------------------
  hub_tier = local.workspace_environment == "live" ? "live" : "nonlive"

  is_ephemeral_hub = local.cluster_environment == "development_cluster"

  # Real BU spokes this permanent hub owns — its own tier only. Empty on
  # ephemeral hubs (they own no real spokes).
  hub_bu_appprojects = local.is_ephemeral_hub ? {} : {
    for key, spoke in local.bu_appprojects : key => spoke
    if spoke.environment == local.hub_tier
  }

  # Convention-paired ephemeral spoke for a dev hub: same account/region,
  # "<prefix>-spoke" derived from the hub's "<prefix>-hub" workspace name.
  ephemeral_spoke_workspace = replace(terraform.workspace, "-hub", "-spoke")
  ephemeral_spoke_registration = local.is_ephemeral_hub ? {
    "${local.ephemeral_spoke_workspace}" = {
      bu_name           = "ephemeral"
      environment       = "nonlive"
      source_repo       = local.environments_repo
      cluster_workspace = local.ephemeral_spoke_workspace
      path_prefix       = "namespaces/ephemeral"
      cluster_arn       = "arn:aws:eks:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:cluster/${local.ephemeral_spoke_workspace}"
      auto_sync         = true
    }
  } : {}

  # Spokes this hub registers: its tier's real BU spokes (permanent hub) or its
  # single convention-paired spoke (ephemeral hub).
  hub_registered_spokes = merge(local.hub_bu_appprojects, local.ephemeral_spoke_registration)
}

#------------------------------------------------------------------------------
# Platform AppProject — deploys infrastructure add-ons to all spoke clusters
#------------------------------------------------------------------------------
resource "kubectl_manifest" "argocd_project_platform_nonlive" {
  count = local.is_argocd_hub && local.hub_tier == "nonlive" ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "platform-nonlive"
      namespace = "argocd"
    }
    spec = {
      description = "Platform infrastructure add-ons deployed to all non-live spoke clusters"
      # Applications are generated by the ApplicationSets into the argocd
      # namespace (apps-in-any-namespace). Each project must permit that source
      # namespace or ArgoCD rejects the project binding on sync.
      sourceNamespaces = ["argocd"]
      sourceRepos = [
        local.environments_repo,
        "${local.environments_repo}.git",
      ]
      # Destinations restricted to the spokes this hub owns (its own tier, or
      # the paired ephemeral spoke on a dev hub).
      destinations = [
        for key, spoke in local.hub_registered_spokes : {
          server    = spoke.cluster_arn
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
  count = local.is_argocd_hub && local.hub_tier == "live" ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "platform-live"
      namespace = "argocd"
    }
    spec = {
      description = "Platform infrastructure add-ons deployed to all live spoke clusters"
      # See platform-nonlive: generated Applications live in the argocd
      # namespace, so it must be an allowed source namespace for this project.
      sourceNamespaces = ["argocd"]
      sourceRepos = [
        local.environments_repo,
        "${local.environments_repo}.git",
      ]
      # Destinations restricted to the spokes this hub owns (its own tier).
      destinations = [
        for key, spoke in local.hub_registered_spokes : {
          server    = spoke.cluster_arn
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
  for_each = local.is_argocd_hub ? local.hub_registered_spokes : {}

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
      # Generated Applications live in the argocd namespace (apps-in-any-namespace),
      # so the project must permit argocd as a source namespace.
      sourceNamespaces = ["argocd"]
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
        { group = "gateway.networking.k8s.io", kind = "ListenerSet" },
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
# Per-BU Workload ApplicationSets — git-directory-generator creates Applications
# automatically when new app deployment directories appear in the monorepo.
# Path: namespaces/<bu>/<product>/<app>/deployment/<env>
# Segments: [namespaces, <bu>, <product>, <app>, deployment, <env>]
#------------------------------------------------------------------------------
resource "kubectl_manifest" "argocd_applicationset_bu" {
  for_each = local.is_argocd_hub ? local.hub_registered_spokes : {}

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
        "container-platform/type"        = "workload"
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
            # One values file per (service, environment) on this cluster tier.
            # File path: namespaces/<bu>/<product>/<service>/deployment/values/<tier>/<env>.yaml
            files = [
              { path = "${each.value.path_prefix}/*/*/deployment/values/${each.value.environment}/*.yaml" }
            ]
          }
        }
      ]
      template = {
        metadata = {
          # dir segments: [namespaces, bu, product, service, deployment, values, tier]
          # filename: <env>.yaml (dev|staging|prod)
          name = "${each.value.bu_name}-{{ index .path.segments 3 }}-{{ trimSuffix \".yaml\" .path.filename }}"
          labels = {
            "container-platform/bu"          = each.value.bu_name
            "container-platform/environment" = "{{ trimSuffix \".yaml\" .path.filename }}"
            "container-platform/product"     = "{{ index .path.segments 2 }}"
            "container-platform/app"         = "{{ index .path.segments 3 }}"
          }
        }
        spec = {
          project = each.key
          source = {
            repoURL        = each.value.source_repo
            targetRevision = "main"
            # Chart dir is the values file's directory minus /values/<tier>
            path = "{{ trimSuffix \"/values/${each.value.environment}\" .path.path }}"
            helm = {
              valueFiles = ["values/${each.value.environment}/{{ .path.filename }}"]
            }
          }
          destination = {
            server = each.value.cluster_arn
            # Namespace comes from the routing key inside the values file
            namespace = "{{ .namespace }}"
          }
          syncPolicy = each.value.auto_sync ? {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = [
              "CreateNamespace=false",
              "PrunePropagationPolicy=foreground",
            ]
            } : {
            automated = null
            syncOptions = [
              "CreateNamespace=false",
            ]
          }
        }
      }
    }
  })

  depends_on = [kubectl_manifest.argocd_project_bu]
}


#------------------------------------------------------------------------------
# Per-BU Baseline ApplicationSets — git-file-generator reads product.yaml
# and renders the app-baseline Helm chart to create Namespace + RoleBinding +
# default-deny NetworkPolicy for each environment on this cluster tier.
#
# Runs under the platform-<env> AppProject (can create Namespaces).
# Always auto-syncs with self-heal to enforce baseline compliance.
#------------------------------------------------------------------------------
resource "kubectl_manifest" "argocd_applicationset_baseline" {
  for_each = local.is_argocd_hub ? local.hub_registered_spokes : {}

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "${each.key}-baselines"
      namespace = "argocd"
      labels = {
        "argocd.argoproj.io/managed-by"  = "terraform"
        "container-platform/bu"          = each.value.bu_name
        "container-platform/environment" = each.value.environment
        "container-platform/type"        = "baseline"
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
            files = [
              { path = "${each.value.path_prefix}/*/product.yaml" }
            ]
          }
        }
      ]
      template = {
        metadata = {
          name = "baseline-${each.value.bu_name}-{{ .product }}-${each.value.environment}"
          labels = {
            "container-platform/bu"          = each.value.bu_name
            "container-platform/environment" = each.value.environment
            "container-platform/type"        = "baseline"
            "container-platform/product"     = "{{ .product }}"
          }
        }
        spec = {
          project = "platform-${each.value.environment}"
          source = {
            repoURL        = each.value.source_repo
            targetRevision = "main"
            path           = "charts/app-baseline"
            helm = {
              valueFiles = [
                "../../${each.value.path_prefix}/{{ .product }}/product.yaml"
              ]
              parameters = [
                {
                  name  = "targetCluster"
                  value = each.value.cluster_workspace
                }
              ]
            }
          }
          destination = {
            server    = each.value.cluster_arn
            namespace = "default"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = [
              "CreateNamespace=false",
              "ServerSideApply=true",
            ]
          }
        }
      }
    }
  })

  depends_on = [
    kubectl_manifest.argocd_project_platform_nonlive,
    kubectl_manifest.argocd_project_platform_live,
  ]
}

#------------------------------------------------------------------------------
# Spoke cluster registration Secrets — required for Argo CD to treat each
# spoke as a deployment target. Without this Secret, Applications targeting
# the spoke's cluster ARN sit in "Unknown" sync state indefinitely: Argo CD
# never attempts to connect until the cluster is registered.
#
# Minimal form only — name + server (the spoke's EKS cluster ARN). No
# config / awsAuthConfig / roleARN block: the EKS-managed Argo CD capability
# authenticates to spoke clusters natively as the hub's capability role (see
# cluster/argocd.tf — aws_eks_access_entry.argocd_spoke_capability), the same
# principal an awsAuthConfig roleARN would otherwise name. That block is only
# needed for self-managed Argo CD assuming a separate cross-account role,
# which this platform does not use.
#------------------------------------------------------------------------------
resource "kubectl_manifest" "argocd_cluster_secret_bu" {
  for_each = local.is_argocd_hub ? local.hub_registered_spokes : {}

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = each.value.cluster_workspace
      namespace = "argocd"
      labels = {
        "argocd.argoproj.io/secret-type" = "cluster"
        "argocd.argoproj.io/managed-by"  = "terraform"
        "container-platform/bu"          = each.value.bu_name
        "container-platform/environment" = each.value.environment
      }
    }
    type = "Opaque"
    stringData = {
      name   = each.value.cluster_workspace
      server = each.value.cluster_arn
    }
  })
}
