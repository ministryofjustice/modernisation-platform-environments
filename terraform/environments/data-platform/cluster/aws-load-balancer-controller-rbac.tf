# The aws-load-balancer-controller Helm chart's ClusterRole does not grant access to
# CustomResourceDefinitions, which the controller needs at startup to detect whether the
# Gateway API CRDs (LoadBalancerConfiguration, TargetGroupConfiguration, ListenerRuleConfiguration)
# are installed. Without this, the controller silently disables the ALBGatewayAPI feature gate.
resource "kubernetes_cluster_role_v1" "aws_load_balancer_controller_crd_reader" {
  metadata {
    name = "aws-load-balancer-controller-crd-reader"
  }

  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "aws_load_balancer_controller_crd_reader" {
  metadata {
    name = "aws-load-balancer-controller-crd-reader"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.aws_load_balancer_controller_crd_reader.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "aws-load-balancer-controller-sa"
    namespace = "kube-system"
  }

  depends_on = [helm_release.aws_load_balancer_controller]
}
