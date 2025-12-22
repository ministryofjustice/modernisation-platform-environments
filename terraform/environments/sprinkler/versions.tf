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
    null = {
      version = "~> 3.2"
      source  = "hashicorp/null"
    }
    time = {
      version = "~> 0.10"
      source  = "hashicorp/time"
    }
  }
  required_version = "~> 1.10"
}
