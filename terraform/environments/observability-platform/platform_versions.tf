terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    grafana = {
      version = "2.6.1"
      source  = "grafana/grafana"
    }
  }
  required_version = "~> 1.0"
}
