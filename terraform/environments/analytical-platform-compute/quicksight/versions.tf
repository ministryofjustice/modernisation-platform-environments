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
    random = {
      version = "~> 3.9"
      source  = "hashicorp/random"
    }
    null = {
      version = "~> 3.3"
      source  = "hashicorp/null"
    }
    archive = {
      version = "~> 2.8"
      source  = "hashicorp/archive"
    }
  }
  required_version = "~> 1.15"
}
