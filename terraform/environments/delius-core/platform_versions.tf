terraform {
  required_providers {
    aws = {
      version = ">= 4.0.0, < 5.0.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
  required_version = "~> 1.0"
}
