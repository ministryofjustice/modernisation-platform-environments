terraform {
  required_providers {
    aws = {
      version = "~> 6.20, != 5.86.0"
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
    null = {
      version = "~> 3.0"
      source  = "hashicorp/null"
    }
    archive = {
      version = "~> 2.0"
      source  = "hashicorp/archive"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  required_version = "~> 1.10"
}
