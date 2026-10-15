terraform {
  required_providers {
    aws = {
      version = "~> 6.0"
      source  = "hashicorp/aws"
    }
    dns = {
      version = "~> 3.0"
      source  = "hashicorp/dns"
    }
    external = {
      version = "~> 2.0"
      source  = "hashicorp/external"
    }
    helm = {
      version = "~> 3.0"
      source  = "hashicorp/helm"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    kubernetes = {
      version = "~> 3.0"
      source  = "hashicorp/kubernetes"
    }
  }
  required_version = "~> 1.0"
}
