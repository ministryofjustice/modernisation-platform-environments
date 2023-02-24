#### This file can be used to store locals specific to the member account ####

locals {

  # sns variables
  pagerduty_integration_keys     = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  pagerduty_integration_key_name = local.application_data.accounts[local.environment].pagerduty_integration_key_name
  sns_topic_name                 = "${local.application_name}-${local.environment}-alerting-topic"
  # environment specfic variables
  # example usage:
  # example_data = local.application_data.accounts[local.environment].example_var
  application_data     = fileexists("./application_variables.json") ? jsondecode(file("./application_variables.json")) : {}
  application_test_url = "https://mlra.dev.legalservices.gov.uk"

}
