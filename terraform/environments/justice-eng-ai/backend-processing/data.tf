# VPC ID exported by the parent justice-eng-ai Terraform root.
data "terraform_remote_state" "justice_eng_ai" {
  backend   = "s3"
  workspace = terraform.workspace

  config = {
    bucket               = "modernisation-platform-terraform-state"
    key                  = "terraform.tfstate"
    region               = "eu-west-2"
    workspace_key_prefix = "environments/members/justice-eng-ai"
  }
}