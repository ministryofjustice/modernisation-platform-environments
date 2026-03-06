terraform {
  required_providers {
    aws = {
      version = "~> 6.27, != 5.86.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
  required_version = "~> 1.10"
}
