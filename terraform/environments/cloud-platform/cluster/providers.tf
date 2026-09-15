# Kubernetes/Helm providers are configured from module.eks outputs rather than a
# data.aws_eks_cluster lookup.
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
