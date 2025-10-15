terraform {
  required_providers {
    aws = {
      version = "~> 6.16"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    template = {
      version = "~> 2.0"
      source  = "hashicorp/template"
    }
  }
  required_version = "~> 1.0"
}
