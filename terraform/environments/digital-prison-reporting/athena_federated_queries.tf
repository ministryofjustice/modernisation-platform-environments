locals {
  # TODO Parameterise NOMIS IP
  #  Dev or Test for now
  nomis_ip_address        = (local.environment == "dev") ? "10.26.24.29" : "10.26.12.239"
  connection_string_nomis = "oracle://jdbc:oracle:thin:$${${aws_secretsmanager_secret.nomis_athena_federated.name}}@${local.nomis_ip_address}:1521:CNOMT3"
}

module "athena_federated_query_connector_oracle" {
  source = "./modules/athena_federated_query_connectors/oracle"

  nomis_cidr                   = "${local.nomis_ip_address}/32"
  spill_bucket_name            = module.s3_working_bucket.bucket_id
  connector_jar_bucket_name    = module.s3_artifacts_store.bucket_id
  connector_jar_bucket_key     = "third-party/athena-connectors/athena-oracle-2024.18.2.jar"
  nomis_credentials_secret_arn = aws_secretsmanager_secret.nomis_athena_federated.arn
  account_id                   = local.account_id
  region                       = local.account_region
  vpc_id                       = data.aws_vpc.shared.id
  subnet_id                    = data.aws_subnet.private_subnets_a.id
  connection_string_nomis      = local.connection_string_nomis
}

# Adds an Athena data source / catalog for NOMIS
resource "aws_athena_data_catalog" "nomis_catalog" {
  name        = "nomis"
  description = "NOMIS Athena data catalog"
  type        = "LAMBDA"

  parameters = {
    "function" = module.athena_federated_query_connector_oracle.lambda_function_arn
  }
}
