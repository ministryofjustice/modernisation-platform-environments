terraform {
  required_providers {
    aws = {
      version = "~> 6.0"
      source  = "hashicorp/aws"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
  }
  required_version = "~> 1.0"
}
