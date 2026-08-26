terraform {
  required_providers {
    aws = {
      version = "~> 6.0"
      source  = "hashicorp/aws"
    }
    # Retained until the Lambda resources have been removed from state.
    external = {
      version = "2.4.0"
      source  = "hashicorp/external"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    local = {
      version = "2.9.0"
      source  = "hashicorp/local"
    }
    null = {
      version = "3.3.0"
      source  = "hashicorp/null"
    }
  }
  required_version = "~> 1.0"
}
