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

    random = {
      version = "~> 3.0"
      source  = "hashicorp/random"
    }

    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
  }
  required_version = "~> 1.0"
}
