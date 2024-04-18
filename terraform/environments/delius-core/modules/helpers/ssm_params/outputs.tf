output "arn_map" {
  value = {for key,value in aws_ssm_parameter.this : key => value.arn}
}
