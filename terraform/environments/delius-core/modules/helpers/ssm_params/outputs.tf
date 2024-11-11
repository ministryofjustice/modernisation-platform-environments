output "arn_map" {
  value = merge(
    { for key, value in aws_ssm_parameter.secure : key => value.arn },
    { for key, value in aws_ssm_parameter.plain : key => value.arn }
  )
}
