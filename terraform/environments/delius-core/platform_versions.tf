terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    external = {
      source = "hashicorp/external"
      version = "2.3.3"
    }
  }
  required_version = "~> 1.0"
}
