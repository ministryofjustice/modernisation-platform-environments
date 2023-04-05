output "provider_original_session" {
  value = data.aws_caller_identity.original_session
}

output "provider_default" {
  value = data.aws_caller_identity.current
}

output "provider_core_vpc" {
  value = data.aws_caller_identity.core_vpc
}

output "provider_core_network_services" {
  value = data.aws_caller_identity.core_network_services
}

output "provider_modernisation_platform" {
  value = data.aws_caller_identity.modernisation_platform
}

output "provider_us_east_1" {
  value = data.aws_caller_identity.us_east_1
}
