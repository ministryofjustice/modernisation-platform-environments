#------------------------------------------------------------------------------
# Amazon CloudWatch Observability — EKS Add-on (Option D)
#
# Deploys the amazon-cloudwatch-observability add-on with OTel Container
# Insights enabled. This provides:
#   - Infrastructure metrics (node, pod, container) with original Prometheus names
#   - Container logs to CloudWatch Logs
#   - PromQL queryable metrics in CloudWatch
#
# The add-on deploys a DaemonSet in the 'amazon-cloudwatch' namespace. It uses
# EKS Pod Identity for IAM credentials.
#
# Key difference from Option A: no separate AMP workspace or ADOT collector.
# Metrics go directly to CloudWatch; AMG queries CloudWatch as a data source.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# IAM role for CloudWatch Observability agent
#------------------------------------------------------------------------------

resource "aws_iam_role" "cloudwatch_observability" {
  count = local.enable_cloudwatch_observability ? 1 : 0

  name = "${local.cluster_name}-cloudwatch-observability"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = merge(local.tags, {
    component = "observability-poc"
    option    = "D-cloudwatch-otel"
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_observability" {
  count = local.enable_cloudwatch_observability ? 1 : 0

  role       = aws_iam_role.cloudwatch_observability[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#------------------------------------------------------------------------------
# EKS Pod Identity Association — binds IAM role to cloudwatch-agent SA
#------------------------------------------------------------------------------

resource "aws_eks_pod_identity_association" "cloudwatch_observability" {
  count = local.enable_cloudwatch_observability ? 1 : 0

  cluster_name    = local.cluster_name
  namespace       = "amazon-cloudwatch"
  service_account = "cloudwatch-agent"
  role_arn        = aws_iam_role.cloudwatch_observability[0].arn

  tags = merge(local.tags, {
    component = "observability-poc"
    option    = "D-cloudwatch-otel"
  })
}

#------------------------------------------------------------------------------
# EKS Add-on — amazon-cloudwatch-observability with OTel Container Insights
#------------------------------------------------------------------------------

resource "aws_eks_addon" "cloudwatch_observability" {
  count = local.enable_cloudwatch_observability ? 1 : 0

  cluster_name                = local.cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    otelContainerInsights = {
      enabled = true
    }
    agents = [
      {
        name = "cloudwatch-agent"
      },
      {
        name = "cloudwatch-agent-cluster-scraper"
        mode = "deployment"
        otelConfig = {
          receivers = {
            "prometheus/kubernetes_services" = {
              config = {
                scrape_configs = [
                  {
                    job_name        = "kubernetes-service-endpoints"
                    scrape_interval = "15s"
                    metrics_path    = "/metrics"
                    kubernetes_sd_configs = [
                      {
                        role = "endpoints"
                      }
                    ]
                    relabel_configs = [
                      {
                        action = "keep"
                        source_labels = [
                          "__meta_kubernetes_service_annotation_prometheus_io_scrape"
                        ]
                        regex = "true"
                      },
                      {
                        action = "keep"
                        source_labels = [
                          "__meta_kubernetes_endpoint_port_name"
                        ]
                        regex = "metrics"
                      },
                      {
                        action = "replace"
                        source_labels = [
                          "__meta_kubernetes_service_annotation_prometheus_io_path"
                        ]
                        regex        = "(.+)"
                        target_label = "__metrics_path__"
                      },
                      {
                        action = "replace"
                        source_labels = [
                          "__meta_kubernetes_namespace"
                        ]
                        target_label = "namespace"
                      },
                      {
                        action = "replace"
                        source_labels = [
                          "__meta_kubernetes_service_name"
                        ]
                        target_label = "service"
                      },
                      {
                        action = "replace"
                        source_labels = [
                          "__meta_kubernetes_pod_name"
                        ]
                        target_label = "pod"
                      }
                    ]
                  }
                ]
              }
            }
          }
          processors = {
            "resource/kubernetes_services" = {
              attributes = [
                {
                  action = "upsert"
                  key    = "k8s.cluster.name"
                  value  = local.cluster_name
                }
              ]
            }
            "batch/kubernetes_services" = {}
          }
          exporters = {
            "otlphttp/kubernetes_services" = {
              metrics_endpoint = "https://monitoring.${data.aws_region.current.region}.amazonaws.com/v1/metrics"
              auth = {
                authenticator = "sigv4auth/kubernetes_services"
              }
            }
          }
          extensions = {
            "sigv4auth/kubernetes_services" = {
              region  = data.aws_region.current.region
              service = "monitoring"
            }
          }
          service = {
            extensions = [
              "sigv4auth/kubernetes_services"
            ]
            pipelines = {
              "metrics/kubernetes_services" = {
                receivers = [
                  "prometheus/kubernetes_services"
                ]
                processors = [
                  "resource/kubernetes_services",
                  "batch/kubernetes_services"
                ]
                exporters = [
                  "otlphttp/kubernetes_services"
                ]
              }
            }
          }
        }
      }
    ]
  })

  tags = merge(local.tags, {
    component = "observability-poc"
    option    = "D-cloudwatch-otel"
  })

  depends_on = [
    aws_eks_pod_identity_association.cloudwatch_observability
  ]
}
