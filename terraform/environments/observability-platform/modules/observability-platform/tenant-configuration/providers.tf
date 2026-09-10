terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.62"
      configuration_aliases = [aws.sso]
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.45"
    }
  }
  required_version = "~> 1.0"
}
