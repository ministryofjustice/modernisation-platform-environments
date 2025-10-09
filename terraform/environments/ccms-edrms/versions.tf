terraform {
  required_providers {
    aws = {
      version = "~> 5.0, != 5.86.0, != 5.99.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    template = {
      version = ">= 2.2.0"
      source  = "hashicorp/template"
    }
  }
  required_version = "~> 1.0"
}
