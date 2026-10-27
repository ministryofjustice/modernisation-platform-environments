# Kubernetes, Helm and kubectl providers are configured from module.eks outputs
# rather than a data.aws_eks_cluster lookup.
#
# Module outputs resolve from state for an existing cluster (endpoint/CA known at
# plan, so the providers reach the real API server and plan-time refresh of
# existing kubernetes_* resources — e.g. the ArgoCD spoke RBAC — works; this
# preserves the #8462 fix), and are known-after-apply on a fresh create (the
# providers fall back to localhost only at plan, when there are no existing k8s
# objects to refresh; at apply the cluster exists and the endpoint resolves, so
# new resources are created against the real cluster).
#
# A data.aws_eks_cluster read would instead do an eager API lookup at plan and
# fail on a brand-new cluster ("reading EKS Cluster: couldn't find resource"),
# which blocked first-time ephemeral deploys.
provider "kubernetes" {
  host                   = try(module.eks.cluster_endpoint, null)
  cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), null)
  token                  = try(data.aws_eks_cluster_auth.cluster.token, null)
}

provider "helm" {
  kubernetes = {
    host                   = try(module.eks.cluster_endpoint, null)
    cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), null)
    token                  = try(data.aws_eks_cluster_auth.cluster.token, null)
  }
}

# kubectl manages the Argo CD BU namespace-boundary admission policy in
# argocd.tf (kubernetes_manifest needs the API server at plan; see argocd.tf).
#
# lazy_load = true is required on a brand-new cluster. Since alekc/kubectl
# 2.3.0 the provider fails at configure time when host/CA/token are unknown
# ("invalid provider configuration: no configuration has been provided"), which
# is always the case at plan before module.eks has created the cluster.
# lazy_load (2.4.0+) defers that error so the plan succeeds; the real client is
# built at apply, after the cluster exists. On existing clusters the module
# outputs are known at plan, so the provider connects as normal.
provider "kubectl" {
  host                   = try(module.eks.cluster_endpoint, null)
  cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), null)
  token                  = try(data.aws_eks_cluster_auth.cluster.token, null)
  load_config_file       = false
  lazy_load              = true
}
