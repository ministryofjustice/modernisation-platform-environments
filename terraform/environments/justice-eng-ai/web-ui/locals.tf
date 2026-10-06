locals {
  # Base name shared by the UI's ALB, target group, ECS cluster/service etc.
  # No environment suffix needed -- development and production are separate
  # AWS accounts, so there's no naming collision to avoid within an account.
  application_resource_name = "${local.application_name}-ui"

  # Per-environment hostnames come from application_variables.json (see
  # local.application_data in platform_locals.tf) so dev and prod stay
  # distinct without hardcoding environment logic here.
  builder_hostname = var.builder_hostname != "" ? var.builder_hostname : local.application_data.accounts[local.environment].builder_hostname

  # Private subnets for ECS/EFS, read from the parent justice-eng-ai root's
  # state (see data.terraform_remote_state.justice_eng_ai in platform_data.tf)
  # since this dedicated VPC is created there, not looked up by tag here.
  private_subnet_ids = data.terraform_remote_state.justice_eng_ai.outputs.private_subnets

  private_subnets_by_key = {
    a = data.terraform_remote_state.justice_eng_ai.outputs.private_subnets[0]
    b = data.terraform_remote_state.justice_eng_ai.outputs.private_subnets[1]
    c = data.terraform_remote_state.justice_eng_ai.outputs.private_subnets[2]
  }
}
