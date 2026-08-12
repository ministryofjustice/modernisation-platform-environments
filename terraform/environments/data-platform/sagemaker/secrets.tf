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

module "justice_transcribe_backend_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=82029345dea22bc49989a6f46c5d8d8e555b84c9" # v2.0.1

  name = "${local.component_name}/justice-transcribe-backend"

  secret_string = jsonencode({
    client_map = {
      client_1 = {
        audience = "api://8d3d0f97-25a3-402b-ae46-606dbbc5e3f4"
        subject  = "9aec1350-e7bc-4f16-98fe-f3ac411bbff4"
      }
      client_2 = {
        audience = "api://22e1db50-b952-4c8d-9d29-c52c5ac89ba4"
        subject  = "0f166e21-97df-4cbe-8d53-6d9a3aaf30fe"
      }
      client_3 = {
        audience = "api://9467c0f9-8b85-4d03-b13b-5be5b0a7ad77"
        subject  = "1d77e7c4-d80d-4c28-8380-d7a3d086e478"
      }
    }
  })
  ignore_secret_changes = true
}
