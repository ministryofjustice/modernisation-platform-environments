terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.45, != 5.71.0"
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
  required_version = "~> 1.0"
}
