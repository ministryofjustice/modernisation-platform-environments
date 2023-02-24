output "acm_certificates" {
  description = "Map of acm_certificates to create depending on options provided"

  value = {
    for key, value in local.acm_certificates : key => value if contains(local.acm_certificates_filter, key)
  }
}

output "iam_roles" {
  description = "Map of iam roles to create depending on options provided"

  value = {
    for key, value in local.iam_roles : key => value if contains(local.iam_roles_filter, key)
  }
}

output "iam_policies" {
  description = "Map of iam policies to create depending on options provided"

  value = {
    for key, value in local.iam_policies : key => value if contains(local.iam_policies_filter, key)
  }
}

output "kms_grants" {
  description = "Map of kms grants to create depending on options provided"

  value = {
    for key, value in local.kms_grants : key => value if contains(local.iam_policies_filter, key)
  }
}

output "s3_iam_policies" {
  description = "Map of iam_policies that can be used to give access to s3_buckets"

  value = var.options.s3_iam_policies != null ? {
    for key, value in local.s3_iam_policies : key => value if contains(var.options.s3_iam_policies, key)
  } : local.s3_iam_policies
}
