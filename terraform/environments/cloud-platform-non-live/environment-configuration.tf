locals {
  environment_configurations = {
    development = {
      account_subdomain_name = "non-live-development.temp.cloud-platform.service.justice.gov.uk"
      ns_records = [
        "ns-1750.awsdns-26.co.uk.",
        "ns-329.awsdns-41.com.",
        "ns-1065.awsdns-05.org.",
        "ns-911.awsdns-49.net."
      ]
    }
    test = {
      account_subdomain_name = "non-live-test.temp.cloud-platform.service.justice.gov.uk"
      ns_records = [
        "ns-81.awsdns-10.com.",
        "ns-1469.awsdns-55.org.",
        "ns-1962.awsdns-53.co.uk.",
        "ns-965.awsdns-56.net."
      ]
    }
    preproduction = {
      account_subdomain_name = "non-live-preproduction.temp.cloud-platform.service.justice.gov.uk"
      ns_records = [
        "ns-2030.awsdns-61.co.uk.",
        "ns-771.awsdns-32.net.",
        "ns-355.awsdns-44.com.",
        "ns-1457.awsdns-54.org."
      ]
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

# commented out as we dont currently have permission to attach policies to the github-actions role
# locals {
#   environment_configurations = {
#     development = {
#       account_subdomain_name = "non-live-development.${local.base_domain}"
#       # Dynamically fetch NS records from development account when running in production workspace
#       ns_records = terraform.workspace == "cloud-platform-non-live-production" && length(data.aws_route53_zone.development_account_zone) > 0 ? [
#         data.aws_route53_zone.development_account_zone[0].name_servers[0],
#         data.aws_route53_zone.development_account_zone[0].name_servers[1],
#         data.aws_route53_zone.development_account_zone[0].name_servers[2],
#         data.aws_route53_zone.development_account_zone[0].name_servers[3],
#       ] : []
#     }
#     test = {
#       account_subdomain_name = "non-live-test.${local.base_domain}"
#       # Dynamically fetch NS records from test account when running in production workspace
#       ns_records = terraform.workspace == "cloud-platform-non-live-production" && length(data.aws_route53_zone.test_account_zone) > 0 ? [
#         data.aws_route53_zone.test_account_zone[0].name_servers[0],
#         data.aws_route53_zone.test_account_zone[0].name_servers[1],
#         data.aws_route53_zone.test_account_zone[0].name_servers[2],
#         data.aws_route53_zone.test_account_zone[0].name_servers[3],
#       ] : []
#     }
#     preproduction = {
#       account_subdomain_name = "non-live-preproduction.${local.base_domain}"
#       # Dynamically fetch NS records from preproduction account when running in production workspace
#       ns_records = terraform.workspace == "cloud-platform-non-live-production" && length(data.aws_route53_zone.preproduction_account_zone) > 0 ? [
#         data.aws_route53_zone.preproduction_account_zone[0].name_servers[0],
#         data.aws_route53_zone.preproduction_account_zone[0].name_servers[1],
#         data.aws_route53_zone.preproduction_account_zone[0].name_servers[2],
#         data.aws_route53_zone.preproduction_account_zone[0].name_servers[3],
#       ] : []
#     }
#     production = {
#       account_subdomain_name = aws_route53_zone.account_zone.name
#       ns_records = length(aws_route53_zone.account_zone) > 0 ? [
#         aws_route53_zone.account_zone.name_servers[0],
#         aws_route53_zone.account_zone.name_servers[1],
#         aws_route53_zone.account_zone.name_servers[2],
#         aws_route53_zone.account_zone.name_servers[3],
#       ] : []
#     }
#   }
# }