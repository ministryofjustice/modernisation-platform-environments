resource "aws_secretsmanager_secret" "component" {
  name        = "component-testbed"
  description = "component environment test"
}