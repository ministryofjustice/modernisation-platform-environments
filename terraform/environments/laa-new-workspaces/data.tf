#### This file can be used to store data specific to the member account ####

##############################################
### Remote state for workspace-components
##############################################
data "terraform_remote_state" "workspace_components" {
  backend = "s3"
  config = {
    acl     = "bucket-owner-full-control"
    bucket  = "modernisation-platform-terraform-state"
    key     = "environments/members/laa-new-workspaces/workspace-components/${terraform.workspace}/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = "true"
  }
}
