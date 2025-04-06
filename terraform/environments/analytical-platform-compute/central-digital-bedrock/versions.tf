terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
    dns = {
      version = "~> 3.0"
      source  = "hashicorp/dns"
    }
    external = {
      version = "~> 2.0"
      source  = "hashicorp/external"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 1.0.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "= 2.2.0"
    }
  }
  required_version = "~> 1.10"
}
