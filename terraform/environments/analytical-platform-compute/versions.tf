terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
    dns = {
      version = "~> 3.0"
      source  = "hashicorp/dns"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    kubernetes = {
      version = "~> 2.0"
      source  = "hashicorp/kubernetes"
    }
    helm = {
      version = "~> 2.0"
      source  = "hashicorp/helm"
    }
    random = {
      version = "~> 3.0"
      source  = "hashicorp/random"
    }
  }
  required_version = "~> 1.0"
}
