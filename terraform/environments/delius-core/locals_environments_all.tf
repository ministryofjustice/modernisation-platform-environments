locals {
  account_info = {
    business_unit    = var.networking[0].business-unit
    region           = "eu-west-2"
    vpc_id           = data.aws_vpc.shared.id
    application_name = local.application_name
    mp_environment   = local.environment
    id               = data.aws_caller_identity.current.account_id
  }

  platform_vars = {
    environment_management = local.environment_management
  }
  bastion = {
    security_group_id = module.bastion_linux.bastion_security_group
  }

  db_config = {
    user_data_param = {
      branch               = "main"
      ansible_repo         = "modernisation-platform-configuration-management"
      ansible_repo_basedir = "ansible"
      ansible_args         = "oracle_19c_install"
    }
    ebs_volumes       = {}
    ebs_volume_config = {}
  }

  # Merge tags from the environment json file with additional ones
  tags_all = merge(
    jsondecode(data.http.environments_file.response_body).tags,
    { "is-production" = local.is-production },
    { "environment-name" = terraform.workspace },
    { "source-code" = "https://github.com/ministryofjustice/modernisation-platform-environments" }
  )
}
