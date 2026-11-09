module "cert_manager" {
  source = "github.com/ministryofjustice/container-platform-terraform-cert-manager?ref=add-depends-on-to-pod-identity"

  cluster_name = local.cluster_name
  hostzones    = ["arn:aws:route53:::hostedzone/*"]

  depends_on = [
    module.envoy_gateway
  ]
}
