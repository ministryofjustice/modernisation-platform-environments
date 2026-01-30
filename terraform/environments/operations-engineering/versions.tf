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
      version = "~> 2.0"
      source  = "hashicorp/archive"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
  required_version = "~> 1.10"
}
