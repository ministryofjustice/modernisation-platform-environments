resource "aws_secretsmanager_secret" "component" {
  name        = "component"
  description = "component environment test"
}
