terraform {
  required_providers {
    aws = {
      version = "~> 6.21, != 5.86.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    null = {
      version = "~> 3.2"
      source  = "hashicorp/null"
    }
    random = {
      version = "~> 3.6"
      source  = "hashicorp/random"
    }
  }
  required_version = "~> 1.10"
}

