terraform {
  required_providers {
    aws = {
      version = "~> 6.16"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    archive = {
      version = "~> 2.8"
      source  = "hashicorp/archive"
    }
    external = {
      version = "~> 2.4"
      source  = "hashicorp/external"
    }
  }
  required_version = "~> 1.10"
}
