variable "name" {
  description = "Name of the Grafana team and folder, also the prefix of the data sources the team can query"
  type        = string
}

variable "github_team" {
  description = "Slug of the GitHub team (in the allowed organisation) synced to the Grafana team"
  type        = string
}

variable "data_source_uids" {
  description = "Data sources the team may query, keyed by a static name. Permissions are per data source; wildcards are not supported"
  type        = map(string)
  default     = {}
}
