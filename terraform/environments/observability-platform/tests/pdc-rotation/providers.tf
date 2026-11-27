provider "grafana" {
  alias = "cloud"
}

provider "grafana" {
  alias = "stack"
}

# Render IAM documents with the real local-only data source, not a mock JSON string.
provider "aws" {
  alias                       = "policy"
  region                      = "eu-west-2"
  access_key                  = "testing"
  secret_key                  = "testing"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}
