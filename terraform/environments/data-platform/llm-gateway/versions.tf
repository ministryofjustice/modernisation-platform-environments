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
      version = "~> 3.0"
      source  = "hashicorp/helm"
    }
    random = {
      version = "~> 3.0"
      source  = "hashicorp/random"
    }
  }
  required_version = "~> 1.0"
}
