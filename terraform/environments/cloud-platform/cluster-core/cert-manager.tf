module "cert_manager" {
  source = "github.com/ministryofjustice/container-platform-terraform-cert-manager?ref=first"

  cluster_name               = local.cluster_name
  hostzones                  = ["arn:aws:route53:::hostedzone/*"]
}