terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }
  }
  required_version = ">= 1.2.5"
}
