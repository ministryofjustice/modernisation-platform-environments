terraform {
  required_providers {
    aws = {
      version = "~> 5.0, != 5.71.0"
      source  = "hashicorp/aws"
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
  }
  required_version = "~> 1.0"
}
