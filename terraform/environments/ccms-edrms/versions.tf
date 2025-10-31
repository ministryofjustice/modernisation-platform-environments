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
  }
  required_version = "~> 1.0"
}
