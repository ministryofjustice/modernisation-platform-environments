terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "2.7.1"
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
      version = "~> 3.2"
      source  = "hashicorp/null"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    template = {
      version = "~> 2.2"
      source  = "hashicorp/template"
    }
  }
  required_version = "~> 1.0"
}
