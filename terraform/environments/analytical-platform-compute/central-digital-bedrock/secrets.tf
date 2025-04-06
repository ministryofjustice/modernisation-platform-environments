# Store vector database credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "vector_db_credentials" {
  name        = "bedrock/vector-db/credentials"
  description = "Credentials for Bedrock vector database"
  kms_key_id  = aws_kms_key.vector_db_kms.arn

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "vector_db_credentials" {
  secret_id = aws_secretsmanager_secret.vector_db_credentials.id
  secret_string = jsonencode({
    username            = "bedrock_${random_string.vector_db_username.result}"
    password            = random_password.vector_db.result
    engine              = "postgres"
    host                = module.vector_db.db_instance_address
    port                = 5432
    dbname              = "vectordb"
    dbClusterIdentifier = module.vector_db.db_instance_identifier
  })
}