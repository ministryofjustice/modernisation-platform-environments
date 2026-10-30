# Backend
terraform {
  # The state bucket lives in the BU live account, not the shared MP account.
  backend "s3" {
    bucket               = "container-platform-cd-live-tf-state-bucket"
    encrypt              = true
    key                  = "terraform.tfstate"
    region               = "eu-west-2"
    use_lockfile         = true
    workspace_key_prefix = "environments/members/container-platform-cd-live" # This will store the object as environments/members/container-platform-cd-live/${workspace}/terraform.tfstate
  }
}
