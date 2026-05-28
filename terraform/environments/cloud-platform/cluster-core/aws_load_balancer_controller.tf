resource "kubernetes_namespace_v1" "aws_load_balancer_controller" {
  metadata {
    name = "aws-load-balancer-controller"

    labels = {
      "name"                                            = "aws-load-balancer-controller"
      "pod-security.kubernetes.io/enforce"              = "privileged"
    }
  }
}

module "aws_load_balancer_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.8.0"

  name = "aws-load-balancer-controller"

  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = local.cluster_name
      namespace       = "aws-load-balancer-controller"
      service_account = "aws-load-balancer-controller-sa"
    }
  }

  tags = local.tags
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  version    = "3.3.0"
  namespace  = "aws-load-balancer-controller"

  values = [
    yamlencode({
      clusterName = local.cluster_name
      vpcId       = data.aws_vpc.selected.id
      serviceAccount = {
        create = true
        name   = module.aws_load_balancer_controller_pod_identity.associations.this.service_account
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.aws_load_balancer_controller,
    module.aws_load_balancer_controller_pod_identity
  ]
}
   

