terraform {
  required_providers {
    aws = {
      version = "~> 5.8"
      source  = "hashicorp/aws"
    }
    cloudinit = {
      version = "~> 2.3.5"
      source  = "hashicorp/cloudinit"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
  }
  required_version = "~> 1.0"
}
