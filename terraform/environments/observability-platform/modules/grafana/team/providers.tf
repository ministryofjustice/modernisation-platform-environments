terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.66, != 5.86.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.47"
    }
  }
  required_version = "~> 1.0"
}
