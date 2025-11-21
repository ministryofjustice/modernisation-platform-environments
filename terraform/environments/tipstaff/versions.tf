terraform {
  required_providers {
    aws = {
      version = "~> 5.0, != 5.86.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    github = {
      version = "~> 4.28.0"
      source  = "integrations/github"
    }
  }
  required_version = "~> 1.10"
}
