##############################################
### Remote State Data Sources
##############################################

# workspace-components: VPC, subnets, RADIUS server, secrets
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

# root module: AD directory, WorkSpaces resources
data "terraform_remote_state" "root" {
  backend = "s3"
  config = {
    acl     = "bucket-owner-full-control"
    bucket  = "modernisation-platform-terraform-state"
    key     = "environments/members/laa-new-workspaces/${terraform.workspace}/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = "true"
  }
}
