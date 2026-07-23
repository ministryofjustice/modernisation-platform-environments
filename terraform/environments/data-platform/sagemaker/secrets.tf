module "elevenlabs_configuration_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=82029345dea22bc49989a6f46c5d8d8e555b84c9" # v2.0.1

  name = "${local.component_name}/elevenlabs-configuration"

  secret_string = jsonencode({
    model_name        = "CHANGEME"
    model_package_arn = "CHANGEME"
    instance_type     = "CHANGEME"
  })
  ignore_secret_changes = true
}

# module "justiceai_entra_application_secret" {
#   count = terraform.workspace == "data-platform-development" ? 1 : 0

#   source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=82029345dea22bc49989a6f46c5d8d8e555b84c9" # v2.0.1

#   name = "${local.component_name}/justiceai-entra-application"

#   secret_string = jsonencode({
#     audience = "CHANGEME"
#     subject  = "CHANGEME"
#   })
#   ignore_secret_changes = true
# }
