output "arn_map" {
  value = merge(
    { for key, value in aws_ssm_parameter.secure : key => value.arn },
    { for key, value in aws_ssm_parameter.plain : key => value.arn }
  )
}

output "param_names" {
  value = concat(
    module.ldap_ssm.params_plain,
    module.ldap_ssm.params_secure
  )
}