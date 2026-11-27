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
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    time = {
      version = "~> 0.10"
      source  = "hashicorp/time"
    }
    tls = {
      version = "~> 4.0"
      source  = "hashicorp/tls"
    }
    null = {
      version = "~> 3.0"
      source  = "hashicorp/null"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    # ~> 2.4 rather than the ~> 2.0 used by the other cloud-platform components:
    # the lazy_load provider argument (see providers.tf) was added in 2.4.0.
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.4"
    }

    cloudinit = {
      version = "~> 2.0"
      source  = "hashicorp/cloudinit"
    }
  }
  required_version = "~> 1.0"
}
