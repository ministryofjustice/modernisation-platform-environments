resource "aws_ssm_parameter" "test" {
  name  = "/terraform/test"
  type  = "String"
  value = "hello"
}