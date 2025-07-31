resource "aws_secretsmanager_secret" "component" {
  name        = "component-playground"
  description = "component environment test"
}