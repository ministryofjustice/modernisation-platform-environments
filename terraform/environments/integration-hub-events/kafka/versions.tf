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
    # Needed to destroy random resources left in state by the removed Slack notifier
    random = {
      version = "~> 3.0"
      source  = "hashicorp/random"
    }
  }
  required_version = "~> 1.0"
}
