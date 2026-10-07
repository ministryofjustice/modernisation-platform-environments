terraform {
  required_providers {
    aws = {
      # >= 6.16.0 for aws_transfer_host_key, used to import the SFTP host key
      # held in Secrets Manager (see transfer-host-key-secret.tf).
      version = ">= 6.16.0, < 7.0.0"
      source  = "hashicorp/aws"
    }
    # Retained until the Lambda resources have been removed from state.
    external = {
      version = "2.4.2"
      source  = "hashicorp/external"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    local = {
      version = "2.9.1"
      source  = "hashicorp/local"
    }
    null = {
      version = "3.3.2"
      source  = "hashicorp/null"
    }
  }
  required_version = "~> 1.0"
}
