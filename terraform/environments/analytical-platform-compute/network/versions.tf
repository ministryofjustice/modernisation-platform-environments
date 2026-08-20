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
      version = "~> 2.4"
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
    time = {
      source  = "hashicorp/time"
      version = "~> 0.14"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.3"
    }
  }
  required_version = "~> 1.15"
}
