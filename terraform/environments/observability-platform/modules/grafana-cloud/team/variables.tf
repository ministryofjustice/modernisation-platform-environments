variable "name" {
  description = "Name of the Grafana team and folder"
  type        = string
}

variable "github_team" {
  description = "Slug of the GitHub team (in the allowed organisation) synced to the Grafana team"
  type        = string
}
