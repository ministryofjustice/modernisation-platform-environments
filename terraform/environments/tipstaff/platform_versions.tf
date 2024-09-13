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
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    github = {
      source = "integrations/github"
      version = "6.2.2"
    }
  }
  required_version = "~> 1.0"
}
