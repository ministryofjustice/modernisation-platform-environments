terraform {
  backend "s3" {
    acl     = "private"
    bucket  = "coat-github-repos-tfstate"
    encrypt = true
    key     = "terraform/github-repos/terraform.tfstate"
    region  = "eu-west-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
  required_version = "~> 1.6"
}

