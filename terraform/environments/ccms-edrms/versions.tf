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
    template = {
      version = "~> 2.2"
      source  = "hashicorp/template"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.8.0"
    }
  }
  required_version = "~> 1.0"
}
