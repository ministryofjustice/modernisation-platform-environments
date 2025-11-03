terraform {
  required_providers {
    aws = {
      version = "~> 6.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    tls = {
      version = "~> 4.0"
      source  = "hashicorp/tls"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    random = {
      version = "~> 3.0"
      source  = "hashicorp/random"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
  required_version = "~> 1.0"
}
