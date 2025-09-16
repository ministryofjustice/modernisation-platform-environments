locals {
  json_links      = regexall("https://download\\.microsoft\\.com/[^\"]*ServiceTags_Public_[^\"]*\\.json", data.http.azure_service_tags_index.response_body)
  latest_json_url = length(local.json_links) > 0 ? local.json_links[0] : ""

  # Parse values array safely
  values = try(jsondecode(data.http.azure_service_tags_json.response_body).values, [])

  auth_tag_names = [
    "AzureActiveDirectory",
    "AzureFrontDoor.Frontend",
  ]

  auth_values = [
    for v in local.values : v
    if contains(local.auth_tag_names, try(v.name, ""))
  ]

  prefixes_all = flatten([
    for v in local.auth_values : try(v.properties.addressPrefixes, [])
  ])

  prefixes_ipv4 = [
    for p in local.prefixes_all : p
    if can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+\\/\\d+$", p))
  ]

  prefixes_ipv4_unique_sorted = sort(distinct(local.prefixes_ipv4))

  capacity_floor       = 400
  prefix_list_capacity = max(length(local.prefixes_ipv4_unique_sorted), local.capacity_floor)

  cloud_platform_ranges = [
    "172.20.0.0/16"
  ]
}