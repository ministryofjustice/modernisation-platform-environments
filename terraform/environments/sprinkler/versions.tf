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
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "1.49.0"
    }
    null = {
      version = "~> 3.2"
      source  = "hashicorp/null"
    }
  }
  required_version = "~> 1.10"
}
