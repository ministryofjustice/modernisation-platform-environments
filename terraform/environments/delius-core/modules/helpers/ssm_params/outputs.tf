output "arn_map" {
  value = merge(
    { for key, value in aws_ssm_parameter.secure : key => value.arn },
    { for key, value in aws_ssm_parameter.plain : key => value.arn }
  )
}

output "plain_param_names" {
  value = [for key, value in var.params_plain : "/${var.environment_name}/${var.application_name}/${key}"]
}

output "secure_param_names" {
  value = [for key, value in var.params_secure : "/${var.environment_name}/${var.application_name}/${key}"]
}

output "param_names" {
  value = concat(
    module.ldap_ssm.plain_param_names,
    module.ldap_ssm.secure_param_names
  )
}