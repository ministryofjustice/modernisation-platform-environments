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
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    helm = {
      version = "~> 3.0"
      source  = "hashicorp/helm"
    }
    kubernetes = {
      version = "~> 2.0"
      source  = "hashicorp/kubernetes"
    }
  }
  required_version = "~> 1.0"
}
