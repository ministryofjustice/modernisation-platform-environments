terraform {
  required_providers {
    aws = {
      version = "~> 6.0"
      source  = "hashicorp/aws"
    }
    kubernetes = {
      version = "~> 2.0"
      source  = "hashicorp/kubernetes"
    }
    helm = {
      version = "~> 2.0"
      source  = "hashicorp/helm"
    }
  }
  required_version = "~> 1.0"
}
