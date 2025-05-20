#### This file can be used to store locals specific to the member account ####


### local varibales for SOA application ####
locals {
  tags = {
    business-unit          = "LAA"
    application            = "CCMS SOA"
    environment-name       = terraform.workspace
    owner                  = "laa-ccms-members@digital.justice.gov.uk"
    infrastructure-support = "laa-role-sre@digital.justice.gov.uk"
    is-production          = terraform.workspace == "production" ? "true" : "false"
    source-code            = "https://github.com/ministryofjustice/modernisation-platform-environments/tree/main/terraform/environments/laa-ccms-soa"
    iac-tool               = "terraform"
  }
}

