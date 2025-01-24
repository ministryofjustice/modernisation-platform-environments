terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2"
    }
  }
  required_version = "~> 1.10"
}
