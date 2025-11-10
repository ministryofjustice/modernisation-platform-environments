locals {
  application_name = "tribunals"

  environment_management = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)

  # Stores modernisation platform account id for setting up the modernisation-platform provider
  modernisation_platform_account_id = data.aws_ssm_parameter.modernisation_platform_account_id.value

  # This takes the name of the Terraform workspace (e.g. core-vpc-production), strips out the application name (e.g. core-vpc), and checks if
  # the string leftover is `-production`, if it isn't (e.g. core-vpc-non-production => -non-production) then it sets the var to false.
  is-production    = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production"
  is-preproduction = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-preproduction"
  is-test          = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-test"
  is-development   = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-development"

  # Merge tags from the environment json file with additional ones
  tags = merge(
    jsondecode(data.http.environments_file.response_body).tags,
    { "is-production" = local.is-production },
    { "environment-name" = terraform.workspace },
    { "source-code" = "https://github.com/ministryofjustice/modernisation-platform-environments" }
  )

  environment     = trimprefix(terraform.workspace, "${var.networking[0].application}-")
  vpc_name        = var.networking[0].business-unit
  subnet_set      = var.networking[0].set
  vpc_all         = "${local.vpc_name}-${local.environment}"
  subnet_set_name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}"

  is_live       = [substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production" || substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-preproduction" ? "live" : "non-live"]
  provider_name = "core-vpc-${local.environment}"

  # environment specfic variables
  # example usage:
  # example_data = local.application_data.accounts[local.environment].example_var
  application_data = fileexists("./application_variables.json") ? jsondecode(file("./application_variables.json")) : null

  common_sans = [
    "*.venues.tribunals.gov.uk",
    "*.reports.tribunals.gov.uk"
  ]

  # the http-only domains only relevant for CloudFront cert
  cloudfront_sans = [
    "siac.tribunals.gov.uk",
    "fhsaa.tribunals.gov.uk",
    "estateagentappeals.tribunals.gov.uk",
    "consumercreditappeals.tribunals.gov.uk",
    "charity.tribunals.gov.uk",
    "adjudicationpanel.tribunals.gov.uk"
  ]

  nonprod_sans = [
    "*.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  ]

  cloudfront_nginx_sans = [
    "asylum-support-tribunal.gov.uk",
    "ahmlr.gov.uk",
    "appeals-service.gov.uk",
    "carestandardstribunal.gov.uk",
    "cicap.gov.uk",
    "civilappeals.gov.uk",
    "cjit.gov.uk",
    "cjs.gov.uk",
    "cjsonline.gov.uk",
    "complaints.judicialconduct.gov.uk",
    "courtfines.justice.gov.uk",
    "courtfunds.gov.uk",
    "criminal-justice-system.gov.uk",
    "dugganinquest.independent.gov.uk",
    "employmentappeals.gov.uk",
    "financeandtaxtribunals.gov.uk",
    "hillsboroughinquests.independent.gov.uk",
    "immigrationservicestribunal.gov.uk",
    "informationtribunal.gov.uk",
    "judicialombudsman.gov.uk",
    "landstribunal.gov.uk",
    "obr.co.uk",
    "osscsc.gov.uk",
    "paroleboard.gov.uk",
    "sendmoneytoaprisoner.justice.gov.uk",
    "transporttribunal.gov.uk",
    "victiminformationservice.org.uk",
    "yjbpublications.justice.gov.uk"
  ]

  cloudfront_nginx_nonprod_sans = []

  cloudfront_distribution_id = data.aws_ssm_parameter.cloudfront_distribution_id.value
}
