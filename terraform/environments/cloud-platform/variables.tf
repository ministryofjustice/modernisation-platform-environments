variable "grafana_url" {
  type        = string
  default     = ""
  description = "AMG workspace endpoint hostname without scheme, e.g. g-xxxx.grafana-workspace.eu-west-2.amazonaws.com. Set by the pipeline on AMG host workspaces so the Grafana provider can manage teams, data sources and permissions. Leave empty on workspaces that do not host AMG."
}
