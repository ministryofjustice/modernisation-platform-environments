terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.68, != 5.86.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.49"
    }
  }
  required_version = "~> 1.0"
}
