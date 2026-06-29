terraform {
  required_version = ">= 1.2.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "> 2.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
  }
}
