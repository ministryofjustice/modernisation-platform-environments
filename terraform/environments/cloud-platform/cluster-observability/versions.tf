terraform {
  required_providers {
    aws = {
      version = "~> 6.0, != 6.57.0"
      source  = "hashicorp/aws"
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
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
  }
  required_version = "~> 1.0"
}
