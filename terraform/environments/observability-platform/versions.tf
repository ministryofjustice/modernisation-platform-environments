terraform {
  required_providers {
    aws = {
      version = "~> 6.72, != 5.86.0"
      source  = "hashicorp/aws"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.54.0"
    }
    github = {
      version = "~> 6.0"
      source  = "integrations/github"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
  }
  required_version = "~> 1.10"
}
