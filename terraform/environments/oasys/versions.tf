terraform {
  required_providers {
    aws = {
      version = "~> 5.0, != 5.86.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.4"
      source  = "hashicorp/http"
    }
    github = {
      version = "~> 4.28.0"
      source  = "integrations/github"
    }
    random = {
      version = "~> 3.6"
      source  = "hashicorp/random"
    }
  }
  required_version = "~> 1.10"
}
