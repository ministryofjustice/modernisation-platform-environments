terraform {
  required_providers {
    aws = {
      version = "~> 6.0"
      source  = "hashicorp/aws"
    }
    github = {
      source  = "integrations/github"
      version = ">= 5.0.0"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
  }
  required_version = "~> 1.0"
}
