module "cert_manager" {
  source = "github.com/ministryofjustice/container-platform-terraform-cert-manager?ref=963f60f1b23291d2d644484189d20f926d405308" #1.0.0

  cluster_name = local.cluster_name
  hostzones    = ["arn:aws:route53:::hostedzone/*"]

  depends_on = [
    module.envoy_gateway
  ]
}