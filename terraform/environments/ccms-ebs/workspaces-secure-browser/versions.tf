terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    aws = {
      version = "~> 5.0, != 5.86.0, != 5.99.0"
      # version = "~> 6.0"
      source  = "hashicorp/aws"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
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
     random = {

      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.1.0"
    }
  }
  required_version = "~> 1.0"
}
