module "cert_manager" {
  source = "./modules/cert-manager"

  cluster_name               = local.cluster_name
  hostzones                  = ["arn:aws:route53:::hostedzone/*"]
}