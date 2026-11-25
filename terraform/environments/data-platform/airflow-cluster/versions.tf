terraform {
  required_providers {
    aws = {
      version = "~> 6.0, != 6.57.0"
      source  = "hashicorp/aws"
    }
    dns = {
      version = "~> 3.0"
      source  = "hashicorp/dns"
    }
    external = {
      version = "~> 2.0"
      source  = "hashicorp/external"
    }
    helm = {
      version = "~> 3.0"
      source  = "hashicorp/helm"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    kubernetes = {
      version = "~> 3.0"
      source  = "hashicorp/kubernetes"
    }
    # Needed only to destroy resources still in state that were created by
    # the EKS/Karpenter modules (OIDC thumbprint, time_sleep, null_resource).
    null = {
      version = "~> 3.0"
      source  = "hashicorp/null"
    }
    time = {
      version = "~> 0.9"
      source  = "hashicorp/time"
    }
    tls = {
      version = "~> 4.0"
      source  = "hashicorp/tls"
    }
  }
  required_version = "~> 1.0"
}