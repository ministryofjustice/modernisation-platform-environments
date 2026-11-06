terraform {
  required_providers {
    aws = {
      version = "~> 6.46"
      source  = "hashicorp/aws"
    }
    dns = {
      version = "~> 3.6"
      source  = "hashicorp/dns"
    }
    external = {
      version = "~> 2.4"
      source  = "hashicorp/external"
    }
    http = {
      version = "~> 3.6"
      source  = "hashicorp/http"
    }
    kubernetes = {
      version = "~> 3.1"
      source  = "hashicorp/kubernetes"
    }
    helm = {
      version = "~> 3.1"
      source  = "hashicorp/helm"
    }
  }
  required_version = "~> 1.15"
}
