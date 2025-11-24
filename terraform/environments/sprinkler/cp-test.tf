resource "aws_ssm_parameter" "cp_test" {
  name  = "cp_test"
  type  = "String"
  value = "This is how we deploy"
}
