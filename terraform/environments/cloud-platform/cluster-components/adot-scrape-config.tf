#------------------------------------------------------------------------------
# ADOT collector Prometheus scrape jobs
#
# Each scrape job for the OpenTelemetryCollector CR in adot.tf is defined here
# as a named local, so adot.tf holds the collector resources and this file
# holds the (larger, growing) scrape configuration. The CR composes these into
# its scrape_configs list.
#
# Target reachability on EKS Auto Mode was verified against a live dev cluster:
#   - cadvisor, kubelet /metrics and /metrics/resource: reachable via the
#     API-server node proxy (nodes/proxy).
#   - apiserver /metrics: reachable via the API-server /metrics endpoint.
#   - CoreDNS: NOT scrapeable on Auto Mode (DNS is AWS-managed, no in-cluster
#     endpoint); intentionally omitted. Tracked for refinement on #7867.
#   - Platform add-on metrics (ExternalDNS, cert-manager, Envoy/Gateway,
#     Gatekeeper) are discovered by the annotation-driven pods/endpoints jobs
#     below once each add-on is annotated at source (follow-up work).
#------------------------------------------------------------------------------

locals {
  # Shared TLS/auth settings for scraping cluster endpoints via the API server.
  adot_in_cluster_tls = {
    ca_file              = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
    insecure_skip_verify = true
  }
  adot_bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"

  # Container metrics: cAdvisor via the API-server node proxy.
  adot_scrape_job_cadvisor = {
    job_name          = "kubernetes-nodes-cadvisor"
    scheme            = "https"
    tls_config        = local.adot_in_cluster_tls
    bearer_token_file = local.adot_bearer_token_file
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
  }

  # Kubelet metrics: pod/workload state, volume stats, running-pod counts,
  # container restart counts. Scraped via the API-server node proxy.
  adot_scrape_job_kubelet = {
    job_name          = "kubernetes-nodes-kubelet"
    scheme            = "https"
    tls_config        = local.adot_in_cluster_tls
    bearer_token_file = local.adot_bearer_token_file
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
        replacement   = "/api/v1/nodes/$1/proxy/metrics"
      }
    ]
  }

  # Kubelet resource metrics: node/container CPU and memory working set from
  # the kubelet's /metrics/resource endpoint, via the API-server node proxy.
  adot_scrape_job_kubelet_resource = {
    job_name          = "kubernetes-nodes-kubelet-resource"
    scheme            = "https"
    tls_config        = local.adot_in_cluster_tls
    bearer_token_file = local.adot_bearer_token_file
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
        replacement   = "/api/v1/nodes/$1/proxy/metrics/resource"
      }
    ]
  }

  # Control plane: API server request rate and latency, plus basic etcd
  # metrics, from the API server's own /metrics endpoint. Reachable on EKS
  # Auto Mode; scheduler/controller-manager metrics are NOT exposed here and
  # are covered via the AWS-native CloudWatch path (#8580).
  adot_scrape_job_apiserver = {
    job_name          = "kubernetes-apiservers"
    scheme            = "https"
    tls_config        = local.adot_in_cluster_tls
    bearer_token_file = local.adot_bearer_token_file
    kubernetes_sd_configs = [
      { role = "endpoints" }
    ]
    relabel_configs = [
      {
        source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_service_name", "__meta_kubernetes_endpoint_port_name"]
        action        = "keep"
        regex         = "default;kubernetes;https"
      }
    ]
  }

  # Annotation-driven pod discovery: scrapes pods carrying
  # prometheus.io/scrape=true (honours prometheus.io/path and /port).
  adot_scrape_job_pods = {
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
  }

  # Annotation-driven service-endpoint discovery: scrapes endpoints behind
  # services carrying prometheus.io/scrape=true. This is how platform add-on
  # metrics (ExternalDNS, cert-manager, etc.) will be collected once their
  # services are annotated at source.
  adot_scrape_job_service_endpoints = {
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

  # Ordered list composed into the collector CR's scrape_configs.
  adot_scrape_configs = [
    local.adot_scrape_job_cadvisor,
    local.adot_scrape_job_kubelet,
    local.adot_scrape_job_kubelet_resource,
    local.adot_scrape_job_apiserver,
    local.adot_scrape_job_pods,
    local.adot_scrape_job_service_endpoints,
  ]
}
