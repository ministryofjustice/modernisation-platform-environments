terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.55.0"
    }
  }
  required_version = "~> 1.10"
}
