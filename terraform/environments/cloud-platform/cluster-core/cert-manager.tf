module "cert_manager" {
  source = "github.com/ministryofjustice/container-platform-terraform-cert-manager?ref=38c59eb430b52c0a69ffb48b69243c9a19a2a43b"

  depends_on = [module.envoy_gateway]

  cluster_name = local.cluster_name
  hostzones    = ["arn:aws:route53:::hostedzone/*"]
}