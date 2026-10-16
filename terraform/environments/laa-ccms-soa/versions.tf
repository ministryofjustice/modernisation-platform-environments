terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "2.8.1"
    }
    aws = {
      version = "~> 6.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
    template = {
      version = "~> 2.2"
      source  = "hashicorp/template"
    }
  }
  required_version = "~> 1.0"
}
