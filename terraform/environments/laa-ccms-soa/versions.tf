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
    archive = {
      source  = "hashicorp/archive"
      version = "2.7.1"
    }
    template = {
      version = "~> 2.2"
      source  = "hashicorp/template"
    }
  }
  required_version = "~> 1.0"
}
