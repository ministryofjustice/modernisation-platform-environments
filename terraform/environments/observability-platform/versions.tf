terraform {
  required_providers {
    aws = {
      version = "~> 6.71, != 5.86.0"
      source  = "hashicorp/aws"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.53"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
  }
  required_version = "~> 1.10"
}
