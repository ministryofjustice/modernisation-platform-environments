terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.21"
      configuration_aliases = [aws.modernisation-platform]
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
  required_version = "~> 1.10"
}
