terraform {
  required_providers {
    aws = {
      version               = "~> 4.0"
      source                = "hashicorp/aws"
      configuration_aliases = [aws.share-host, aws.share-tenant]
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
    // Keeping this provider until it gets fazed out in member accounts
    #template = {
    #  source  = "hashicorp/template"
    #  version = "~> 2.2"
    #}
  }
  required_version = ">= 1.0.1"
}
