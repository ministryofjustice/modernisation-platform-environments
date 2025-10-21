terraform {
  required_providers {
    aws = {
      version = "~> 6.0"
      source  = "hashicorp/aws"
    }
    archive = {
      version = "~> 2.4"
      source  = "hashicorp/archive"
    }
  }
  required_version = "~> 1.10"
}
