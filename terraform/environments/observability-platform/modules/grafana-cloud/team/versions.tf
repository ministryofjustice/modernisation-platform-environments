terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.25.9"
    }
  }
  required_version = "~> 1.10"
}
