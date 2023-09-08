##################################################
# Apps and Tools
##################################################

resource "aws_ses_domain_identity" "apps_tools" {
  domain = local.environment_configuration.ses_domain_identity
}
