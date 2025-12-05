terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.21, != 5.86.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
  }
  required_version = "~> 1.0"
}
