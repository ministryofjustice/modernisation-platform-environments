terraform {
  required_providers {
    aws = {
      # 6.69.0 regression: "bufio.Scanner: token too long" on >64KB API bodies (hashicorp/terraform-provider-aws#50472)
      version = "~> 6.46, != 6.69.0"
      source  = "hashicorp/aws"
    }
    dns = {
      version = "~> 3.6"
      source  = "hashicorp/dns"
    }
    external = {
      version = "~> 2.4"
      source  = "hashicorp/external"
    }
    http = {
      version = "~> 3.6"
      source  = "hashicorp/http"
    }
  }
  required_version = "~> 1.15"
}
