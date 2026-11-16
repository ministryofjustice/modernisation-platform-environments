locals {
  nomis_host              = jsondecode(data.aws_secretsmanager_secret_version.nomis.secret_string)["endpoint"]
  nomis_port              = jsondecode(data.aws_secretsmanager_secret_version.nomis.secret_string)["port"]
  nomis_service_name      = jsondecode(data.aws_secretsmanager_secret_version.nomis.secret_string)["db_name"]
  connection_string_nomis = "oracle://jdbc:oracle:thin:$${${aws_secretsmanager_secret.nomis.name}}@//${local.nomis_host}:${local.nomis_port}/${local.nomis_service_name}"

  bodmis_host              = jsondecode(data.aws_secretsmanager_secret_version.bodmis.secret_string)["endpoint"]
  bodmis_port              = jsondecode(data.aws_secretsmanager_secret_version.bodmis.secret_string)["port"]
  bodmis_service_name      = jsondecode(data.aws_secretsmanager_secret_version.bodmis.secret_string)["db_name"]
  connection_string_bodmis = "oracle://jdbc:oracle:thin:$${${aws_secretsmanager_secret.bodmis.name}}@//${local.bodmis_host}:${local.bodmis_port}/${local.bodmis_service_name}"

  oasys_host              = local.is-test ? jsondecode(data.aws_secretsmanager_secret_version.oasys[0].secret_string)["endpoint"] : ""
  oasys_port              = local.is-test ? jsondecode(data.aws_secretsmanager_secret_version.oasys[0].secret_string)["port"] : ""
  oasys_service_name      = local.is-test ? jsondecode(data.aws_secretsmanager_secret_version.oasys[0].secret_string)["db_name"] : ""
  connection_string_oasys = local.is-test ? "oracle://jdbc:oracle:thin:$${${aws_secretsmanager_secret.oasys[0].name}}@//${local.oasys_host}:${local.oasys_port}/${local.oasys_service_name}" : ""

  onr_host              = local.is-test ? jsondecode(data.aws_secretsmanager_secret_version.onr[0].secret_string)["endpoint"] : ""
  onr_port              = local.is-test ? jsondecode(data.aws_secretsmanager_secret_version.onr[0].secret_string)["port"] : ""
  onr_service_name      = local.is-test ? jsondecode(data.aws_secretsmanager_secret_version.onr[0].secret_string)["db_name"] : ""
  connection_string_onr = local.is-test ? "oracle://jdbc:oracle:thin:$${${aws_secretsmanager_secret.onr[0].name}}@//${local.onr_host}:${local.onr_port}/${local.onr_service_name}" : ""

  ndelius_host              = local.is-test ? jsondecode(data.aws_secretsmanager_secret_version.ndelius[0].secret_string)["endpoint"] : ""
  ndelius_port              = local.is-test ? jsondecode(data.aws_secretsmanager_secret_version.ndelius[0].secret_string)["port"] : ""
  ndelius_service_name      = local.is-test ? jsondecode(data.aws_secretsmanager_secret_version.ndelius[0].secret_string)["db_name"] : ""
  connection_string_ndelius = local.is-test ? "oracle://jdbc:oracle:thin:$${${aws_secretsmanager_secret.ndelius[0].name}}@//${local.ndelius_host}:${local.ndelius_port}/${local.ndelius_service_name}" : ""

  ndmis_host              = local.is_non_prod ? jsondecode(data.aws_secretsmanager_secret_version.ndmis[0].secret_string)["endpoint"] : ""
  ndmis_port              = local.is_non_prod ? jsondecode(data.aws_secretsmanager_secret_version.ndmis[0].secret_string)["port"] : ""
  ndmis_service_name      = local.is_non_prod ? jsondecode(data.aws_secretsmanager_secret_version.ndmis[0].secret_string)["db_name"] : ""
  connection_string_ndmis = local.is_non_prod ? "oracle://jdbc:oracle:thin:$${${aws_secretsmanager_secret.ndmis[0].name}}@//${local.ndmis_host}:${local.ndmis_port}/${local.ndmis_service_name}" : ""

  # The Oracle databases each connector serves in each environment. Each database has a catalog of the same name.
  # Prisons and probation have a connector each, so each can be granted to its own parent domain.
  federated_query_oracle_databases = {
    development = {
      prisons   = ["nomis", "bodmis"]
      probation = ["ndmis"]
    }
    test = {
      prisons   = ["nomis", "bodmis"]
      probation = ["oasys", "onr", "ndelius", "ndmis"]
    }
    preproduction = {
      prisons   = ["nomis", "bodmis"]
      probation = ["ndmis"]
    }
    production = {
      prisons   = ["nomis", "bodmis"]
      probation = []
    }
  }[local.environment]

  # The secrets for oasys, onr, ndelius and ndmis only exist in some environments, so their ARNs are null elsewhere
  federated_query_oracle_connections = {
    nomis   = { connection_string = local.connection_string_nomis, secret_arn = aws_secretsmanager_secret.nomis.arn }
    bodmis  = { connection_string = local.connection_string_bodmis, secret_arn = aws_secretsmanager_secret.bodmis.arn }
    oasys   = { connection_string = local.connection_string_oasys, secret_arn = one(aws_secretsmanager_secret.oasys[*].arn) }
    onr     = { connection_string = local.connection_string_onr, secret_arn = one(aws_secretsmanager_secret.onr[*].arn) }
    ndelius = { connection_string = local.connection_string_ndelius, secret_arn = one(aws_secretsmanager_secret.ndelius[*].arn) }
    ndmis   = { connection_string = local.connection_string_ndmis, secret_arn = one(aws_secretsmanager_secret.ndmis[*].arn) }
  }
}

module "athena_federated_query_connector_oracle" {
  source = "./modules/athena_federated_query_connectors"

  #checkov:skip=CKV_AWS_25
  #checkov:skip=CKV_AWS_23
  #checkov:skip=CKV_AWS_277
  #checkov:skip=CKV_AWS_260
  #checkov:skip=CKV_AWS_24
  #checkov:skip=CKV_AWS_117
  #checkov:skip=CKV_AWS_363
  #checkov:skip=CKV_AWS_63:Ensure no IAM policies documents allow "*" as a statement's actions
  #checkov:skip=CKV_AWS_62:Ensure IAM policies that allow full "*-*" administrative privileges are not created
  #checkov:skip=CKV_AWS_61:Ensure AWS IAM policy does not allow assume role permission across all service
  #checkov:skip=CKV_AWS_60:Ensure IAM role allows only specific services or principals to assume it
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy  

  name                                  = "${local.project}-athena-federated-query-oracle"
  connector_jar_bucket_key              = local.athena_oracle_connector_jar_key
  connector_jar_bucket_name             = module.s3_artifacts_store.bucket_id
  spill_bucket_name                     = module.s3_working_bucket.bucket_id
  credentials_secret_arns               = [for db in local.federated_query_oracle_databases.prisons : local.federated_query_oracle_connections[db].secret_arn]
  project_prefix                        = local.project
  account_id                            = local.account_id
  region                                = local.account_region
  vpc_id                                = data.aws_vpc.shared.id
  subnet_id                             = data.aws_subnet.private_subnets_a.id
  lambda_memory_allocation_mb           = local.federated_query_lambda_memory_mb
  lambda_timeout_seconds                = local.federated_query_lambda_timeout_seconds
  lambda_reserved_concurrent_executions = local.federated_query_lambda_concurrent_executions
  lambda_handler                        = local.lambda_oracle_handler
  athena_connector_type                 = local.athena_oracle_connector_type

  # A map that links catalog names to database connection strings
  connection_strings = { for db in local.federated_query_oracle_databases.prisons : db => local.federated_query_oracle_connections[db].connection_string }
}

module "athena_federated_query_connector_oracle_probation" {
  source = "./modules/athena_federated_query_connectors"
  count  = length(local.federated_query_oracle_databases.probation) > 0 ? 1 : 0

  #checkov:skip=CKV_AWS_25
  #checkov:skip=CKV_AWS_23
  #checkov:skip=CKV_AWS_277
  #checkov:skip=CKV_AWS_260
  #checkov:skip=CKV_AWS_24
  #checkov:skip=CKV_AWS_117
  #checkov:skip=CKV_AWS_363
  #checkov:skip=CKV_AWS_63:Ensure no IAM policies documents allow "*" as a statement's actions
  #checkov:skip=CKV_AWS_62:Ensure IAM policies that allow full "*-*" administrative privileges are not created
  #checkov:skip=CKV_AWS_61:Ensure AWS IAM policy does not allow assume role permission across all service
  #checkov:skip=CKV_AWS_60:Ensure IAM role allows only specific services or principals to assume it
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy  

  name                                  = "${local.project}-athena-federated-query-oracle-probation"
  connector_jar_bucket_key              = local.athena_oracle_connector_jar_key
  connector_jar_bucket_name             = module.s3_artifacts_store.bucket_id
  spill_bucket_name                     = module.s3_working_bucket.bucket_id
  credentials_secret_arns               = [for db in local.federated_query_oracle_databases.probation : local.federated_query_oracle_connections[db].secret_arn]
  project_prefix                        = local.project
  account_id                            = local.account_id
  region                                = local.account_region
  vpc_id                                = data.aws_vpc.shared.id
  subnet_id                             = data.aws_subnet.private_subnets_a.id
  lambda_memory_allocation_mb           = local.federated_query_lambda_memory_mb
  lambda_timeout_seconds                = local.federated_query_lambda_timeout_seconds
  lambda_reserved_concurrent_executions = local.federated_query_lambda_concurrent_executions
  lambda_handler                        = local.lambda_oracle_handler
  athena_connector_type                 = local.athena_oracle_connector_type

  # A map that links catalog names to database connection strings
  connection_strings = { for db in local.federated_query_oracle_databases.probation : db => local.federated_query_oracle_connections[db].connection_string }
}

# ORACLE ATHENA DATA CATALOGS
# ---------------------------

# Adds an Athena data source / catalog for NOMIS
resource "aws_athena_data_catalog" "nomis_catalog" {
  name        = "nomis"
  description = "NOMIS Athena data catalog"
  type        = "LAMBDA"

  parameters = {
    "function" = module.athena_federated_query_connector_oracle.lambda_function_arn
  }
}


# Adds an Athena data source / catalog for Bodmis
resource "aws_athena_data_catalog" "bodmis_catalog" {
  name        = "bodmis"
  description = "BODMIS Athena data catalog"
  type        = "LAMBDA"

  parameters = {
    "function" = module.athena_federated_query_connector_oracle.lambda_function_arn
  }
}

# Adds an Athena data source / catalog for OASys
resource "aws_athena_data_catalog" "oasys_catalog" {
  count = contains(local.federated_query_oracle_databases.probation, "oasys") ? 1 : 0

  name        = "oasys"
  description = "OASys Athena data catalog"
  type        = "LAMBDA"

  parameters = {
    "function" = module.athena_federated_query_connector_oracle_probation[0].lambda_function_arn
  }
}

# Adds an Athena data source / catalog for ONR
resource "aws_athena_data_catalog" "onr_catalog" {
  count = contains(local.federated_query_oracle_databases.probation, "onr") ? 1 : 0

  name        = "onr"
  description = "ONR Athena data catalog"
  type        = "LAMBDA"

  parameters = {
    "function" = module.athena_federated_query_connector_oracle_probation[0].lambda_function_arn
  }
}

# Adds an Athena data source / catalog for nDelius
resource "aws_athena_data_catalog" "ndelius_catalog" {
  count = contains(local.federated_query_oracle_databases.probation, "ndelius") ? 1 : 0

  name        = "ndelius"
  description = "nDelius Athena data catalog"
  type        = "LAMBDA"

  parameters = {
    "function" = module.athena_federated_query_connector_oracle_probation[0].lambda_function_arn
  }
}

# Adds an Athena data source / catalog for ndmis
resource "aws_athena_data_catalog" "ndmis_catalog" {
  count = contains(local.federated_query_oracle_databases.probation, "ndmis") ? 1 : 0

  name        = "ndmis"
  description = "ndmis Athena data catalog"
  type        = "LAMBDA"

  parameters = {
    "function" = module.athena_federated_query_connector_oracle_probation[0].lambda_function_arn
  }
}
