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
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.0" # Use the latest version or specify your desired version
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3.0" # Use the latest version or specify your desired version
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = "~> 1.0"
}
