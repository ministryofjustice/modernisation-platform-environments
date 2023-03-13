terraform {
  required_providers {
    aws = {
      version = ">= 4.0.0, < 5.0.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.4"
    }
  }
  required_version = "~> 1.0"
}
