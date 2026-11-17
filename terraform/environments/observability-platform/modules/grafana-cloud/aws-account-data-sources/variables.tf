variable "name" {
  description = "Name of the AWS account, used as the prefix of the data source names"
  type        = string
}

variable "role_arn" {
  description = "ARN of the IAM role in the account that Grafana Cloud assumes with Grafana Assume Role"
  type        = string
}

variable "cloudwatch" {
  description = "CloudWatch data source settings"
  type = object({
    enabled           = bool
    custom_namespaces = list(string)
  })
}

variable "xray" {
  description = "X-Ray data source settings"
  type = object({
    enabled = bool
  })
}

variable "amazon_prometheus" {
  description = "Amazon Managed Service for Prometheus workspace to query. No data source when null"
  type = object({
    workspace_id = string
    region       = string
  })
  default = null
}

variable "query_team_ids" {
  description = "IDs of the Grafana teams that can query the data sources"
  type        = list(string)
}
