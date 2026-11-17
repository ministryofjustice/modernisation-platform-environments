variable "stack_slug" {
  description = "Slug of the Grafana Cloud stack, used to find its built-in data sources"
  type        = string
}

variable "metrics" {
  description = "Grafana Cloud Metrics (Mimir) query URL and basic auth username"
  type = object({
    url      = string
    username = string
  })
}

variable "logs" {
  description = "Grafana Cloud Logs (Loki) query URL and basic auth username"
  type = object({
    url      = string
    username = string
  })
}

variable "traces" {
  description = "Grafana Cloud Traces (Tempo) query URL and basic auth username"
  type = object({
    url      = string
    username = string
  })
}

variable "read_token" {
  description = "Grafana Cloud access policy token used by the data sources. It must be read only, with no label selectors: they would take precedence over the data sources' label-based access control rules"
  type        = string
  sensitive   = true
}

variable "teams" {
  description = "Grafana teams, keyed by tenant name, with the names of the accounts each team can query that push each signal"
  type = map(object({
    id  = string
    uid = string
    accounts = object({
      metrics = list(string)
      logs    = list(string)
      traces  = list(string)
    })
  }))
}

variable "account_ids" {
  description = "AWS account IDs, keyed by account name, for the accounts in teams. Only used in the label-based access control rules"
  type        = map(string)
  sensitive   = true
}
