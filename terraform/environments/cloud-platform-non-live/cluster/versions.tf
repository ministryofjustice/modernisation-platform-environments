terraform {
  required_providers {
    aws = {
      version = "~> 6.0"
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
    time = {
      version = "~> 0.10"
      source  = "hashicorp/time"
    }
    tls = {
      version = "~> 4.0"
      source  = "hashicorp/tls"
    }
    null = {
      version = "~> 3.0"
      source  = "hashicorp/null"
    }
  }
  required_version = "~> 1.0"
}
