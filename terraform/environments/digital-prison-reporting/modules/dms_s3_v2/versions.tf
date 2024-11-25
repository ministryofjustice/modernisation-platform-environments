terraform {
  required_providers {
    aws = {
      version = ">= 5.31.0"
      source  = "hashicorp/aws"
    }

    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }

  }
  required_version = "~> 1.0"
}
