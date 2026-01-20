# locals {
#   environment_configurations = {
#     development = {
#       account_subdomain_name = "non-live-development.temp.cloud-platform.service.justice.gov.uk"
#       ns_records = [
#         "ns-1509.awsdns-60.org.",
#         "ns-205.awsdns-25.com.",
#         "ns-1550.awsdns-01.co.uk.",
#         "ns-899.awsdns-48.net."
#       ]
#     }
#     test = {
#       account_subdomain_name = "non-live-test.temp.cloud-platform.service.justice.gov.uk"
#       ns_records = [
#         "ns-792.awsdns-35.net.",
#         "ns-110.awsdns-13.com.",
#         "ns-1592.awsdns-07.co.uk.",
#         "ns-1245.awsdns-27.org."
#       ]
#     }
#     preproduction = {
#       account_subdomain_name = "non-live-preproduction.temp.cloud-platform.service.justice.gov.uk"
#       ns_records = [
#         "ns-1801.awsdns-33.co.uk.",
#         "ns-728.awsdns-27.net.",
#         "ns-1172.awsdns-18.org.",
#         "ns-454.awsdns-56.com."
#       ]
#     }
#     production = {
#       account_subdomain_name = length(aws_route53_zone.account_zone) > 0 ? aws_route53_zone.account_zone[0].name : "production.temp.cloud-platform.service.justice.gov.uk"
#       ns_records = length(aws_route53_zone.account_zone) > 0 ? [
#         aws_route53_zone.account_zone[0].name_servers[0],
#         aws_route53_zone.account_zone[0].name_servers[1],
#         aws_route53_zone.account_zone[0].name_servers[2],
#         aws_route53_zone.account_zone[0].name_servers[3],
#       ] : []
#     }
#   }
# }
