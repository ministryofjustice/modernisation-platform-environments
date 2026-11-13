terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.72, != 5.86.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.53"
    }
  }
  required_version = "~> 1.0"
}
