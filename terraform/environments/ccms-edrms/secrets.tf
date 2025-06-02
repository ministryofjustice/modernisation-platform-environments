#### This file can be used to store secrets specific to the member account ####

resource "aws_secretsmanager_secret" "spring_datasource_password" {
  name        = "ccms/edrms/datasource"
  description = "SOA TDS database password for CCMS EDRMS application"
}