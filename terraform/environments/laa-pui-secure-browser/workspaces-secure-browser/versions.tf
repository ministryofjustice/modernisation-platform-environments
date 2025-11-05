terraform {
  required_providers {
    aws = {
      version = "~> 6.0"
      source  = "hashicorp/aws"
    }
    dns = {
      version = "~> 3.4"
      source  = "hashicorp/dns"
    }
    external = {
      version = "~> 2.3"
      source  = "hashicorp/external"
    }
    http = {
      version = "~> 3.5"
      source  = "hashicorp/http"
    }
    random = {
      version = "~> 3.7"
      source  = "hashicorp/random"
    }
  }
  required_version = "~> 1.0"
}
