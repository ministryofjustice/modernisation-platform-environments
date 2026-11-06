# Keep the bootstrap component state in the shared MP state bucket. The
# dedicated PagerDuty state bucket created by this component is for the
# integration-hub repository's PagerDuty Terraform only.
terraform {
  backend "s3" {
    acl                  = "bucket-owner-full-control"
    bucket               = "modernisation-platform-terraform-state"
    encrypt              = true
    key                  = "terraform.tfstate"
    region               = "eu-west-2"
    use_lockfile         = true
    workspace_key_prefix = "environments/members/integration-hub/iac"
  }
}
