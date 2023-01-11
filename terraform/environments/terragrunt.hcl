locals {
  application_name = path_relative_to_include()
}
inputs = { # pass vars to terraform
  application_name = local.application_name
}

remote_state {
  backend = "s3"
  config = {
    bucket               = "modernisation-platform-terraform-state"
    key                  = "terraform.tfstate"
    region               = "eu-west-2"
    encrypt              = true
    acl                  = "bucket-owner-full-control"
    workspace_key_prefix = "environments/members/${local.application_name}" # This will store the object as environments/core-shared-services/${workspace}/imagebuilder-[team name].tfstate
  }
}
