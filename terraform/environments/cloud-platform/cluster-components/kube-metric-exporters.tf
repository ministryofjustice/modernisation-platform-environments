#------------------------------------------------------------------------------
# Metric exporters: node-exporter and kube-state-metrics
#
# These provide the metric sources that the ADOT collector (adot.tf) scrapes
# but that the cluster does not emit on its own:
#   - node-exporter (DaemonSet): node/host CPU, memory, filesystem, load.
#   - kube-state-metrics (Deployment): pod phase, container restart counts,
#     running-pod counts, and other workload-state metrics.
#
# Both are deployed into a dedicated `monitoring` namespace and expose a
# Prometheus-annotated Service, so the collector's existing annotation-driven
# `kubernetes-service-endpoints` scrape job discovers them with no collector
# changes. Gated on the same enable_amp_adot flag as the rest of the pipeline.
#
# EKS Auto Mode / Gatekeeper constraints accounted for here:
#   - The cluster enforces `user-ns-require-psa-label` (deny): the namespace
#     must carry a pod-security.kubernetes.io/enforce label.
#   - The cluster enforces `k8sdisallowhostnetwork` (deny): node-exporter is
#     configured with hostNetwork=false. It still reads host metrics via
#     hostPID and the host /proc, /sys, and root mounts (not blocked), and is
#     scraped on the pod IP, so no host-level metrics are lost.
#------------------------------------------------------------------------------

resource "kubernetes_namespace_v1" "monitoring" {
  count = local.enable_amp_adot ? 1 : 0

  metadata {
    name = "monitoring"
    labels = {
      # Required by the k8srequiredlabels / user-ns-require-psa-label
      # Gatekeeper constraint. node-exporter needs host access, so this
      # namespace runs privileged (consistent with cert-manager,
      # envoy-gateway-system, and gatekeeper-system).
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

#------------------------------------------------------------------------------
# node-exporter — node/host metrics (DaemonSet, one pod per node)
#------------------------------------------------------------------------------

resource "helm_release" "node_exporter" {
  count = local.enable_amp_adot ? 1 : 0

  name       = "node-exporter"
  namespace  = kubernetes_namespace_v1.monitoring[0].metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-node-exporter"
  version    = "4.59.0"

  # Fail the apply (rather than leave a half-released chart) if the release
  # does not become ready.
  atomic          = true
  cleanup_on_fail = true
  timeout         = 300

  values = [yamlencode({
    # hostNetwork is denied by the k8sdisallowhostnetwork constraint; disable
    # it. node-exporter binds to the pod IP and is scraped there instead.
    hostNetwork = false
    hostPID     = true

    # Annotate the Service so the collector's kubernetes-service-endpoints
    # job discovers it (port 9100, path /metrics).
    service = {
      annotations = {
        "prometheus.io/scrape" = "true"
        "prometheus.io/port"   = "9100"
      }
    }

    # Keep the chart's non-root, read-only-root-fs security defaults explicit.
    securityContext = {
      runAsNonRoot = true
      runAsUser    = 65534
      runAsGroup   = 65534
      fsGroup      = 65534
    }

    resources = {
      requests = { cpu = "20m", memory = "32Mi" }
      limits   = { memory = "64Mi" }
    }
  })]

  depends_on = [kubernetes_namespace_v1.monitoring]
}

#------------------------------------------------------------------------------
# kube-state-metrics — workload-state metrics (single Deployment)
#------------------------------------------------------------------------------

resource "helm_release" "kube_state_metrics" {
  count = local.enable_amp_adot ? 1 : 0

  name       = "kube-state-metrics"
  namespace  = kubernetes_namespace_v1.monitoring[0].metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-state-metrics"
  version    = "8.4.2"

  atomic          = true
  cleanup_on_fail = true
  timeout         = 300

  values = [yamlencode({
    # prometheusScrape=true (chart default) adds prometheus.io/scrape to the
    # Service; set the port annotation explicitly so the collector's
    # service-endpoints job targets 8080/metrics.
    prometheusScrape = true
    service = {
      port = 8080
      annotations = {
        "prometheus.io/port" = "8080"
      }
    }

    resources = {
      requests = { cpu = "20m", memory = "64Mi" }
      limits   = { memory = "128Mi" }
    }
  })]

  depends_on = [kubernetes_namespace_v1.monitoring]
}
