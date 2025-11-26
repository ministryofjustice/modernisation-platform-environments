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
    random = {
      version = "~> 3.0"
      source  = "hashicorp/random"
    }
    null = {
      version = "~> 3.0"
      source  = "hashicorp/null"
    }
  }
  required_version = "~> 1.10"
}
