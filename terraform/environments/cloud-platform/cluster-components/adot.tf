#------------------------------------------------------------------------------
# AWS Distro for OpenTelemetry (ADOT) — EKS Add-on
#
# Deploys the ADOT operator on the cluster. The operator manages
# OpenTelemetryCollector CRDs which define the actual scrape/export pipeline.
#
# Prerequisites:
#   - cert-manager must be installed (deployed in cluster-core)
#   - Pod Identity association created in amp.tf
#
# The ADOT add-on installs the operator only. The collector configuration
# (what to scrape, where to export) is defined via an OpenTelemetryCollector
# custom resource below.
#------------------------------------------------------------------------------

resource "aws_eks_addon" "adot" {
  count = local.enable_amp_adot ? 1 : 0

  cluster_name                = local.cluster_name
  addon_name                  = "adot"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(local.tags, {
    component = "observability-poc"
    option    = "A-amp-adot"
  })
}

#------------------------------------------------------------------------------
# OpenTelemetryCollector CR — configures ADOT to scrape Prometheus metrics
# and remote-write to AMP.
#
# Deployed as a DaemonSet to collect node-level and pod metrics from every node.
# Uses the service account bound to the AMP remote-write IAM role via Pod Identity.
#------------------------------------------------------------------------------

# The opentelemetry-operator-system namespace is created and owned by the ADOT
# EKS add-on itself, so Terraform must not manage it (doing so races the add-on
# and fails with "namespace already exists"). The namespace is on the Gatekeeper
# PSA-label exclusion list, so it does not need an explicit enforce label.

resource "kubernetes_service_account_v1" "adot_collector" {
  count = local.enable_amp_adot ? 1 : 0

  metadata {
    name      = "adot-collector"
    namespace = "opentelemetry-operator-system"
  }

  depends_on = [aws_eks_addon.adot]
}

resource "kubectl_manifest" "adot_collector" {
  count = local.enable_amp_adot ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "opentelemetry.io/v1beta1"
    kind       = "OpenTelemetryCollector"
    metadata = {
      name      = "adot-amp"
      namespace = "opentelemetry-operator-system"
    }
    spec = {
      mode           = "daemonset"
      serviceAccount = "adot-collector"
      config = yamlencode({
        receivers = {
          prometheus = {
            config = {
              global = {
                scrape_interval = "60s"
                scrape_timeout  = "15s"
              }
              scrape_configs = [
                {
                  job_name = "kubernetes-nodes-cadvisor"
                  scheme   = "https"
                  tls_config = {
                    ca_file              = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
                    insecure_skip_verify = true
                  }
                  bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
                  kubernetes_sd_configs = [
                    { role = "node" }
                  ]
                  relabel_configs = [
                    {
                      action = "labelmap"
                      regex  = "__meta_kubernetes_node_label_(.+)"
                    },
                    {
                      target_label = "__address__"
                      replacement  = "kubernetes.default.svc:443"
                    },
                    {
                      source_labels = ["__meta_kubernetes_node_name"]
                      regex         = "(.+)"
                      target_label  = "__metrics_path__"
                      replacement   = "/api/v1/nodes/$1/proxy/metrics/cadvisor"
                    }
                  ]
                },
                {
                  job_name = "kubernetes-pods"
                  kubernetes_sd_configs = [
                    { role = "pod" }
                  ]
                  relabel_configs = [
                    {
                      source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
                      action        = "keep"
                      regex         = "true"
                    },
                    {
                      source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
                      action        = "replace"
                      target_label  = "__metrics_path__"
                      regex         = "(.+)"
                    },
                    {
                      source_labels = ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
                      action        = "replace"
                      regex         = "([^:]+)(?::\\d+)?;(\\d+)"
                      replacement   = "$1:$2"
                      target_label  = "__address__"
                    },
                    {
                      action = "labelmap"
                      regex  = "__meta_kubernetes_pod_label_(.+)"
                    },
                    {
                      source_labels = ["__meta_kubernetes_namespace"]
                      action        = "replace"
                      target_label  = "namespace"
                    },
                    {
                      source_labels = ["__meta_kubernetes_pod_name"]
                      action        = "replace"
                      target_label  = "pod"
                    }
                  ]
                },
                {
                  job_name = "kubernetes-service-endpoints"
                  kubernetes_sd_configs = [
                    { role = "endpoints" }
                  ]
                  relabel_configs = [
                    {
                      source_labels = ["__meta_kubernetes_service_annotation_prometheus_io_scrape"]
                      action        = "keep"
                      regex         = "true"
                    },
                    {
                      source_labels = ["__meta_kubernetes_service_annotation_prometheus_io_path"]
                      action        = "replace"
                      target_label  = "__metrics_path__"
                      regex         = "(.+)"
                    },
                    {
                      source_labels = ["__address__", "__meta_kubernetes_service_annotation_prometheus_io_port"]
                      action        = "replace"
                      regex         = "([^:]+)(?::\\d+)?;(\\d+)"
                      replacement   = "$1:$2"
                      target_label  = "__address__"
                    },
                    {
                      action = "labelmap"
                      regex  = "__meta_kubernetes_service_label_(.+)"
                    },
                    {
                      source_labels = ["__meta_kubernetes_namespace"]
                      action        = "replace"
                      target_label  = "namespace"
                    },
                    {
                      source_labels = ["__meta_kubernetes_service_name"]
                      action        = "replace"
                      target_label  = "service"
                    }
                  ]
                }
              ]
            }
          }
        }
        processors = {
          batch = {
            timeout         = "60s"
            send_batch_size = 1000
          }
        }
        exporters = {
          prometheusremotewrite = {
            endpoint = "${aws_prometheus_workspace.this[0].prometheus_endpoint}api/v1/remote_write"
            auth = {
              authenticator = "sigv4auth"
            }
          }
        }
        extensions = {
          sigv4auth = {
            region  = data.aws_region.current.region
            service = "aps"
          }
        }
        service = {
          extensions = ["sigv4auth"]
          pipelines = {
            metrics = {
              receivers  = ["prometheus"]
              processors = ["batch"]
              exporters  = ["prometheusremotewrite"]
            }
          }
        }
      })
    }
  })

  depends_on = [
    aws_eks_addon.adot,
    kubernetes_service_account_v1.adot_collector,
    aws_eks_pod_identity_association.adot_amp
  ]
}
