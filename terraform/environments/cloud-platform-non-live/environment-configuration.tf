locals {
  environment_configurations = {
    development = {
      account_subdomain_name = "non-live-development.${local.base_domain}"
      # Dynamically fetch NS records from development account when running in production workspace
      ns_records = terraform.workspace == "cloud-platform-non-live-production" && length(data.aws_route53_zone.development_account_zone) > 0 ? [
        data.aws_route53_zone.development_account_zone[0].name_servers[0],
        data.aws_route53_zone.development_account_zone[0].name_servers[1],
        data.aws_route53_zone.development_account_zone[0].name_servers[2],
        data.aws_route53_zone.development_account_zone[0].name_servers[3],
      ] : []
    }
    test = {
      account_subdomain_name = "non-live-test.${local.base_domain}"
      # Dynamically fetch NS records from test account when running in production workspace
      ns_records = terraform.workspace == "cloud-platform-non-live-production" && length(data.aws_route53_zone.test_account_zone) > 0 ? [
        data.aws_route53_zone.test_account_zone[0].name_servers[0],
        data.aws_route53_zone.test_account_zone[0].name_servers[1],
        data.aws_route53_zone.test_account_zone[0].name_servers[2],
        data.aws_route53_zone.test_account_zone[0].name_servers[3],
      ] : []
    }
    preproduction = {
      account_subdomain_name = "non-live-preproduction.${local.base_domain}"
      # Dynamically fetch NS records from preproduction account when running in production workspace
      ns_records = terraform.workspace == "cloud-platform-non-live-production" && length(data.aws_route53_zone.preproduction_account_zone) > 0 ? [
        data.aws_route53_zone.preproduction_account_zone[0].name_servers[0],
        data.aws_route53_zone.preproduction_account_zone[0].name_servers[1],
        data.aws_route53_zone.preproduction_account_zone[0].name_servers[2],
        data.aws_route53_zone.preproduction_account_zone[0].name_servers[3],
      ] : []
    }
    production = {
      account_subdomain_name = aws_route53_zone.account_zone.name
      ns_records = length(aws_route53_zone.account_zone) > 0 ? [
        aws_route53_zone.account_zone.name_servers[0],
        aws_route53_zone.account_zone.name_servers[1],
        aws_route53_zone.account_zone.name_servers[2],
        aws_route53_zone.account_zone.name_servers[3],
      ] : []
    }
  }
}
