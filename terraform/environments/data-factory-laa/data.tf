#### This file can be used to store data specific to the member account ####
data "aws_secretsmanager_secret_version" "fabric_tenant_id" {
  secret_id = aws_secretsmanager_secret.fabric_tenant_id.id
}

data "aws_secretsmanager_secret_version" "fabric_enterprise_app_object_id" {
  secret_id = aws_secretsmanager_secret.fabric_enterprise_app_object_id.id
}