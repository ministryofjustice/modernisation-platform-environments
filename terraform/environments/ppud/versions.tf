terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      version = "~> 4.0"
      source  = "hashicorp/aws"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }

    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }
  }
}
