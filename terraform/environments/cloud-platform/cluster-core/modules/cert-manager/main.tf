resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"

    labels = {
      "name"                                            = "cert-manager"
      "pod-security.kubernetes.io/enforce"              = "privileged"
    }
  }
}

module "cert_manager_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "cert-manager"

  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = var.hostzones

  associations = {
    this = {
      cluster_name    = var.cluster_name
      namespace       = kubernetes_namespace_v1.cert_manager.metadata[0].name
      service_account = "cert-manager"
    }
  }
}

resource "helm_release" "cert_manager" {
  name          = "cert-manager"
  chart         = "cert-manager"
  repository    = "https://charts.jetstack.io"
  namespace     = kubernetes_namespace_v1.cert_manager.metadata[0].name
  version       = "v1.20.3"
  recreate_pods = true

  values = [templatefile("${path.module}/templates/values.yaml.tpl", {
    certman_replicas = var.certman_replicas
    webhook_replicas = var.webhook_replicas
    cainjector_replicas = var.cainjector_replicas
  })]

  lifecycle {
    ignore_changes = [keyring]
  }
}

resource "kubectl_manifest" "clusterissuers_staging" {
  yaml_body = templatefile("${path.module}/templates/clusterIssuers.yaml.tpl", {
    env         = "staging"
    acme_server = "https://acme-staging-v02.api.letsencrypt.org/directory"
  })

  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "clusterissuers_production" {
  yaml_body = templatefile("${path.module}/templates/clusterIssuers.yaml.tpl", {
    env         = "production"
    acme_server = "https://acme-v02.api.letsencrypt.org/directory"
  })

  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "clusterissuer_selfsigned" {
  yaml_body = file("${path.module}/templates/clusterIssuer-selfsigned.yaml")

  depends_on = [helm_release.cert_manager]
}