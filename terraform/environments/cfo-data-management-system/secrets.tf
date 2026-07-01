# RabbitMQ Password
resource "random_password" "rabbitmq" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "rabbitmq-password" {
  name        = "${local.application_name_short}/${local.environment}/rabbitmq-password"
  description = "RabbitMQ master password for ${local.application_name_short} ${local.environment} environment"
  kms_key_id  = data.aws_kms_key.general_shared.arn
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "rabbitmq-password" {
  secret_id     = aws_secretsmanager_secret.rabbitmq-password.id
  secret_string = random_password.rabbitmq.result
}

# API Auth Key
resource "random_password" "api-key" {
  length  = 48
  special = false
}

# App Secrets — third-party credentials and tuneable config managed manually via the AWS console.
# lifecycle ignore_changes preserves manual updates on subsequent Terraform applies.
resource "aws_secretsmanager_secret" "app-secrets" {
  name        = "${local.application_name_short}/${local.environment}/app-secrets"
  description = "Application credentials and tuneable config for ${local.application_name_short} ${local.environment}"
  kms_key_id  = data.aws_kms_key.general_shared.arn
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "app-secrets" {
  secret_id = aws_secretsmanager_secret.app-secrets.id

  secret_string = jsonencode({
    # Azure AD
    Client_ID             = "CHANGE_ME"
    Client_Secret         = "CHANGE_ME"
    API_Client_ID         = "CHANGE_ME"
    # API auth — auto-generated on first create; share with callers via Secrets Manager
    Authentication_ApiKey = random_password.api-key.result
    # Sentry
    Sentry_Dsn            = "CHANGE_ME"
    # RabbitMQ — auto-populated; update CatsRabbitMQ manually
    RabbitMQ     = "amqp://user:${random_password.rabbitmq.result}@${aws_instance.rabbitmq.private_dns}:5672"
    CatsRabbitMQ = "CHANGE_ME"
    # FileSync tuneable config — update in the console without needing a Terraform apply
    FileSync_ProcessOnStartup            = "true"
    FileSync_ProcessTimerIntervalSeconds = "300"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# DB Config — SQL Server connection strings
resource "aws_secretsmanager_secret" "db-config" {
  name        = "${local.application_name_short}/${local.environment}/db-config"
  description = "Auto-generated SQL Server connection strings for ${local.application_name_short} ${local.environment}"
  kms_key_id  = data.aws_kms_key.general_shared.arn
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "db-config" {
  secret_id = aws_secretsmanager_secret.db-config.id

  secret_string = jsonencode({
    AuditDb                = "Data Source=${data.aws_db_instance.rds.address},1433;Initial Catalog=AuditDb;User Id=dbadmin;Password=${jsondecode(data.aws_secretsmanager_secret_version.rds-master-password.secret_string)["password"]};TrustServerCertificate=true"
    DeliusRunningPictureDb = "Data Source=${data.aws_db_instance.rds.address},1433;Initial Catalog=DeliusRunningPictureDb;User Id=dbadmin;Password=${jsondecode(data.aws_secretsmanager_secret_version.rds-master-password.secret_string)["password"]};TrustServerCertificate=true"
    OfflocRunningPictureDb = "Data Source=${data.aws_db_instance.rds.address},1433;Initial Catalog=OfflocRunningPictureDb;User Id=dbadmin;Password=${jsondecode(data.aws_secretsmanager_secret_version.rds-master-password.secret_string)["password"]};TrustServerCertificate=true"
    ClusterDb              = "Data Source=${data.aws_db_instance.rds.address},1433;Initial Catalog=ClusterDb;User Id=dbadmin;Password=${jsondecode(data.aws_secretsmanager_secret_version.rds-master-password.secret_string)["password"]};TrustServerCertificate=true"
    MatchingDb             = "Data Source=${data.aws_db_instance.rds.address},1433;Initial Catalog=MatchingDb;User Id=dbadmin;Password=${jsondecode(data.aws_secretsmanager_secret_version.rds-master-password.secret_string)["password"]};TrustServerCertificate=true"
    DeliusStagingDb        = "Data Source=${data.aws_db_instance.rds.address},1433;Initial Catalog=DeliusStagingDb;User Id=dbadmin;Password=${jsondecode(data.aws_secretsmanager_secret_version.rds-master-password.secret_string)["password"]};TrustServerCertificate=true"
    OfflocStagingDb        = "Data Source=${data.aws_db_instance.rds.address},1433;Initial Catalog=OfflocStagingDb;User Id=dbadmin;Password=${jsondecode(data.aws_secretsmanager_secret_version.rds-master-password.secret_string)["password"]};TrustServerCertificate=true"
  })
}

# Deployment config — infrastructure references auto-populated by Terraform.
resource "aws_secretsmanager_secret" "deployment" {
  name        = "${local.application_name_short}/${local.environment}/deployment"
  description = "Infrastructure references for GitHub Actions deployment workflows — managed by Terraform"
  kms_key_id  = data.aws_kms_key.general_shared.arn
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "deployment" {
  secret_id = aws_secretsmanager_secret.deployment.id
  secret_string = jsonencode({
    # GitHub Actions OIDC
    GithubActionsRoleArn = module.github-actions-oidc-role.role
    # ECR / ECS
    ECRRepositoryUrl = aws_ecr_repository.app.repository_url
    ECSClusterName   = "${local.application_name_short}-${local.environment}-cluster"
    # RDS — informational, used when inspecting infrastructure or constructing manual queries
    RDSEndpoint = data.aws_db_instance.rds.address
    # Non-sensitive application config injected as container environment variables at deploy time
    S3BucketName = module.s3-bucket-files.bucket.id
    APIBaseURL   = "https://${local.application_data.accounts[local.environment].api_domain}"
    DMSFilesBasePath = "/mnt/efs"
  })
}