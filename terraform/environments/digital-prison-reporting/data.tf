# Source Nomis Secrets
data "aws_secretsmanager_secret" "nomis" {
  name = aws_secretsmanager_secret.nomis.id

  depends_on = [aws_secretsmanager_secret_version.nomis]
}

data "aws_secretsmanager_secret_version" "nomis" {
  secret_id = data.aws_secretsmanager_secret.nomis.id

  depends_on = [aws_secretsmanager_secret.nomis]
}

# Source Bodmis Secrets
data "aws_secretsmanager_secret" "bodmis" {
  name = aws_secretsmanager_secret.bodmis.id

  depends_on = [aws_secretsmanager_secret_version.bodmis]
}

data "aws_secretsmanager_secret_version" "bodmis" {
  secret_id = data.aws_secretsmanager_secret.bodmis.id

  depends_on = [aws_secretsmanager_secret.bodmis]
}

# Source OASys Secrets
data "aws_secretsmanager_secret" "oasys" {
  count = local.is-test ? 1 : 0

  name = aws_secretsmanager_secret.oasys[0].id

  depends_on = [aws_secretsmanager_secret_version.oasys[0]]
}

data "aws_secretsmanager_secret_version" "oasys" {
  count = local.is-test ? 1 : 0

  secret_id = data.aws_secretsmanager_secret.oasys[0].id

  depends_on = [aws_secretsmanager_secret.oasys[0]]
}

# Source ONR Secrets
data "aws_secretsmanager_secret" "onr" {
  count = local.is-test ? 1 : 0

  name = aws_secretsmanager_secret.onr[0].id

  depends_on = [aws_secretsmanager_secret_version.onr[0]]
}

data "aws_secretsmanager_secret_version" "onr" {
  count = local.is-test ? 1 : 0

  secret_id = data.aws_secretsmanager_secret.onr[0].id

  depends_on = [aws_secretsmanager_secret.onr[0]]
}

# Source nDelius Secrets
data "aws_secretsmanager_secret" "ndelius" {
  count = local.is-test ? 1 : 0

  name = aws_secretsmanager_secret.ndelius[0].id

  depends_on = [aws_secretsmanager_secret_version.ndelius[0]]
}

data "aws_secretsmanager_secret_version" "ndelius" {
  count = local.is-test ? 1 : 0

  secret_id = data.aws_secretsmanager_secret.ndelius[0].id

  depends_on = [aws_secretsmanager_secret.ndelius[0]]
}

# Source nDelius Secrets
data "aws_secretsmanager_secret" "ndmis" {
  count = local.is_non_prod ? 1 : 0

  name = aws_secretsmanager_secret.ndmis[0].id

  depends_on = [aws_secretsmanager_secret_version.ndmis[0]]
}

data "aws_secretsmanager_secret_version" "ndmis" {
  count = local.is_non_prod ? 1 : 0

  secret_id = data.aws_secretsmanager_secret.ndmis[0].id

  depends_on = [aws_secretsmanager_secret.ndmis[0]]
}


# Source DataMart Secrets
data "aws_secretsmanager_secret" "datamart" {
  name = aws_secretsmanager_secret.redshift.id

  depends_on = [aws_secretsmanager_secret_version.redshift]
}

data "aws_secretsmanager_secret_version" "datamart" {
  secret_id = data.aws_secretsmanager_secret.datamart.id

  depends_on = [aws_secretsmanager_secret.redshift]
}

# Source DPS Secrets
data "aws_secretsmanager_secret" "dps" {
  for_each = toset(local.dps_domains_list)
  name     = "external/${local.project}-${each.value}-source-secrets"

  depends_on = [aws_secretsmanager_secret_version.dps]
}

data "aws_secretsmanager_secret_version" "dps" {
  for_each = toset(local.dps_domains_list)

  secret_id = data.aws_secretsmanager_secret.dps[each.value].id

  depends_on = [aws_secretsmanager_secret.dps]
}

# DPR Secret
data "aws_secretsmanager_secret" "test_db" {
  count = local.is_dev_or_test ? 1 : 0

  name = "external/${local.project}-dps-test-db-source-secrets"
}

data "aws_secretsmanager_secret_version" "test_db" {
  count = local.is_dev_or_test ? 1 : 0

  secret_id = data.aws_secretsmanager_secret.test_db[0].id
}

# AWS _IAM_ Policy
data "aws_iam_policy" "rds_full_access" {
  #checkov:skip=CKV_AWS_275:Disallow policies from using the AWS AdministratorAccess policy

  arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

# Get APIGateway Endpoint ID
data "aws_vpc_endpoint" "api" {
  provider     = aws.core-vpc
  vpc_id       = data.aws_vpc.shared.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.execute-api"
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-com.amazonaws.${data.aws_region.current.name}.execute-api"
  }
}

# Get slack integration url
data "aws_secretsmanager_secret" "slack_integration" {
  count      = local.enable_slack_alerts ? 1 : 0
  depends_on = [module.slack_alerts_url]
  name       = "${local.project}-slack-alerts-url-${local.environment}"
}

data "aws_secretsmanager_secret_version" "slack_integration" {
  count     = local.enable_slack_alerts ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.slack_integration[0].id
}

# Get pagerduty integration url
data "aws_secretsmanager_secret" "pagerduty_integration" {
  count      = local.enable_pagerduty_alerts ? 1 : 0
  depends_on = [module.pagerduty_integration_key]
  name       = "${local.project}-pagerduty-integration-key-${local.environment}"
}

data "aws_secretsmanager_secret_version" "pagerduty_integration" {
  count     = local.enable_pagerduty_alerts ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration[0].id
}

# Source Analytics DBT Secrets
data "aws_secretsmanager_secret" "dbt_secrets" {
  name = aws_secretsmanager_secret.dbt_secrets[0].id

  depends_on = [aws_secretsmanager_secret_version.dbt_secrets]
}

data "aws_secretsmanager_secret_version" "dbt_secrets" {
  secret_id = data.aws_secretsmanager_secret.dbt_secrets.id

  depends_on = [aws_secretsmanager_secret.dbt_secrets]
}


# TLS Certificate for OIDC URL, DBT K8s Platform
data "tls_certificate" "dbt_analytics" {
  url = "https://oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.dbt_secrets.secret_string)["oidc_cluster_identifier"]}"
}

# AWS Secrets Manager for Operational DB Credentials
data "aws_secretsmanager_secret" "operational_db_secret" {
  name = aws_secretsmanager_secret.operational_db_secret.name
}

data "aws_secretsmanager_secret_version" "operational_db_secret_version" {
  secret_id = data.aws_secretsmanager_secret.operational_db_secret.id
}

# AWS Secrets Manager for Transfer Component Role Credentials
data "aws_secretsmanager_secret" "transfer_component_role_secret" {
  name = aws_secretsmanager_secret.transfer_component_role_secret.name
}

data "aws_secretsmanager_secret_version" "transfer_component_role_secret_version" {
  secret_id = data.aws_secretsmanager_secret.transfer_component_role_secret.id
}

# For Lakeformation Management

# Retrieves the source role of terraform's current caller identity
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

# Retrieves role for data-engineers

data "aws_iam_roles" "data_engineering_roles" {
  name_regex = "AWSReservedSSO_modernisation-platform-data-eng.*"
}

# Retrieves role for developers

data "aws_iam_roles" "developer_roles" {
  name_regex = "AWSReservedSSO_modernisation-platform-developer.*"
}
