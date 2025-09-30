terraform {
  required_providers {
    aws = {
      version = "~> 6.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    tls = {
      version = "~> 4.0"
      source  = "hashicorp/tls"
    }
    random = {
      version = "~> 3.0"
      source  = "hashicorp/random"
    }
    template = {
      version = "~> 2.0"
      source  = "hashicorp/template"
    }
  }
  required_version = "~> 1.0"
}
