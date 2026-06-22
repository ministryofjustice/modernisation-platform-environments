resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  chart      = "cert-manager"
  repository = "oci://quay.io/jetstack/charts"
  version    = "v1.20.2"
  namespace  = "cert-manager"

  set = [{
    name  = "crds.enabled"
    value = "true"
  }, {
    name  = "config.apiVersion"
    value = "controller.config.cert-manager.io/v1alpha1"
  }, {
    name  = "config.kind"
    value = "ControllerConfiguration"
  }, {
    name  = "config.enableGatewayAPI"
    value = "true"
  }, {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cert_manager.arn
  }]

  depends_on = [kubernetes_namespace_v1.cert_manager, aws_iam_role.cert_manager]
}

resource "kubernetes_manifest" "clusterissuer_selfsigned" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "selfsigned"
    }
    spec = {
      selfSigned = {}
    }
  }

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_manifest" "clusterissuer_letsencrypt_staging" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-staging"
    }
    spec = {
      acme = {
        server   = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email    = "platforms@digital.justice.gov.uk"
        privateKeySecretRef = {
          name = "letsencrypt-staging"
        }
        solvers = [
          {
            dns01 = {
              route53 = {}
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_manifest" "clusterissuer_letsencrypt_prod" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server   = "https://acme-v02.api.letsencrypt.org/directory"
        email    = "platforms@digital.justice.gov.uk"
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [
          {
            dns01 = {
              route53 = {}
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}
