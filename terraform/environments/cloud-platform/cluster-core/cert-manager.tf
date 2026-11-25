module "cert_manager" {
  source = "github.com/ministryofjustice/container-platform-terraform-cert-manager?ref=e76dac1a60bf66f05d7802ee4c13cbb5b6d4f040" #2.0.0

  cluster_name = local.cluster_name
  hostzones    = ["arn:aws:route53:::hostedzone/*"]

  depends_on = [
    module.envoy_gateway
  ]
}