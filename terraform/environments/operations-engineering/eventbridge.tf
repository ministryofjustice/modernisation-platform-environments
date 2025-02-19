# alpha-analytics-moj

module "alpha-analytics-moj" {
  source = "./modules/eventbridge"

  event_source = "aws.partner/auth0.com/alpha-analytics-moj-9790e567-420a-48b2-b978-688dd998d26c/auth0.logs"
}

# justice-cloud-platform

module "justice-cloud-platform" {
  source = "./modules/eventbridge"

  event_source = "aws.partner/auth0.com/justice-cloud-platform-9bea4c89-7006-4060-94f8-ef7ed853d946/auth0.logs"
}

# ministryofjustice

module "ministryofjustice" {
  source = "./modules/eventbridge"

  event_source = "aws.partner/auth0.com/ministryofjustice-775267e6-72e7-46a5-9059-a396cd0625e7/auth0.logs"
}

# operations-engineering

module "operations-engineering" {
  source = "./modules/eventbridge"

  event_source = "aws.partner/auth0.com/operations-engineering-4d9a5624-861c-4871-981e-fce33be08149/auth0.logs"
}