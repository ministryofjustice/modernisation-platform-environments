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
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    awscc = {
      source = "hashicorp/awscc"
      version = "~> 1.0"
  }
  required_version = "~> 1.10"
}
