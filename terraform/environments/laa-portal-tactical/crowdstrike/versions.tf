terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
    crowdstrike = {
      source  = "crowdstrike/crowdstrike"
      version = ">= 0.0.18"
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
  }
  required_version = "~> 1.10"
}