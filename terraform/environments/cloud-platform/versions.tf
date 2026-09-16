terraform {
  required_providers {
    aws = {
      version = "~> 6.0, != 6.57.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.46"
    }
  }
  required_version = "~> 1.0"
}
