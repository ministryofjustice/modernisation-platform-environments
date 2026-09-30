###################
# K8S - Namespace #
###################

resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"

    labels = {
      "component"                          = "logging"
      "pod-security.kubernetes.io/enforce" = "privileged"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"                = "Logging"
      "cloud-platform.justice.gov.uk/business-unit"              = "Platforms"
      "cloud-platform.justice.gov.uk/owner"                      = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"                = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "cloud-platform.justice.gov.uk/can-tolerate-master-taints" = "true"
      "cloud-platform.justice.gov.uk/slack-channel"              = "cloud-platform"
      "cloud-platform-out-of-hours-alert"                        = "true"
    }
  }
}

###############
# fluent-bit #
###############

resource "helm_release" "fluent_bit" {

  name       = "fluent-bit"
  chart      = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  namespace  = kubernetes_namespace.logging.id
  version    = "0.54.0"
  timeout    = 1500

  values = [templatefile("${path.module}/templates/fluent-bit.yaml.tpl", {
    # opensearch_app_host               = var.opensearch_app_host
    # elasticsearch_host                = var.elasticsearch_host
    # s3_bucket_application_logs        = module.s3_bucket_application_logs.bucket_name
    s3_bucket_application_logs       = "${local.cluster_name}-${each.value}-s3"
    cluster                           = terraform.workspace
  })]

  depends_on = [kubernetes_service_account.this]
}


####################
# Network Policies #
####################

resource "kubernetes_network_policy" "default" {
  metadata {
    name      = "default"
    namespace = kubernetes_namespace.logging.id
  }

  spec {
    pod_selector {}
    ingress {
      from {
        pod_selector {}
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "allow_prometheus_scraping" {
  metadata {
    name      = "allow-prometheus-scraping"
    namespace = kubernetes_namespace.logging.id
  }

  spec {
    pod_selector {}
    ingress {
      from {
        namespace_selector {
          match_labels = {
            component = "monitoring"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

##################
# Resource Quota #
##################

resource "kubernetes_resource_quota" "namespace_quota" {
  metadata {
    name      = "namespace-quota"
    namespace = kubernetes_namespace.logging.id
  }
  spec {
    hard = {
      pods = 170
    }
  }
}

##############
# LimitRange #
##############

resource "kubernetes_limit_range" "default" {
  metadata {
    name      = "limitrange"
    namespace = kubernetes_namespace.logging.id
  }
  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "4"
        memory = "5500Mi"
      }
      default_request = {
        cpu    = "100m"
        memory = "300Mi"
      }
    }
  }
}