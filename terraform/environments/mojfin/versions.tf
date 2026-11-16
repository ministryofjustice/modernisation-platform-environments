terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    aws = {
      version = "~> 6.0"
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
      version = "~> 3.5"
    }
  }
  required_version = "~> 1.10"
}
