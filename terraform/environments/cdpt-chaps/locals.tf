locals {
  app_data = jsondecode(file("./application_variables.json"))

  task_definition = templatefile("task_definition.json", {
    app_name            = local.application_name
    ecr_url             = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/cdpt-chaps-ecr-repo"
    docker_image_tag    = local.application_data.accounts[local.environment].docker_image_tag
    region              = local.application_data.accounts[local.environment].region
  })

  # user_data = base64encode(file("./user-data.txt"))
  user_data = base64encode(templatefile("user_data.sh", {
    app_name = local.application_name
  }))
}
