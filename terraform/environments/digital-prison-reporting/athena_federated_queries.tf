locals {
  nomis_host              = jsondecode(data.aws_secretsmanager_secret_version.nomis.secret_string)["endpoint"]
  nomis_port              = jsondecode(data.aws_secretsmanager_secret_version.nomis.secret_string)["port"]
  nomis_service_name      = jsondecode(data.aws_secretsmanager_secret_version.nomis.secret_string)["db_name"]
  connection_string_nomis = "oracle://jdbc:oracle:thin:$${${aws_secretsmanager_secret.nomis.name}}@//${local.nomis_host}:${local.nomis_port}/${local.nomis_service_name}"

  bodmis_host              = jsondecode(data.aws_secretsmanager_secret_version.bodmis.secret_string)["endpoint"]
  bodmis_service_name      = jsondecode(data.aws_secretsmanager_secret_version.bodmis.secret_string)["db_name"]
  connection_string_bodmis = "oracle://jdbc:oracle:thin:$${${aws_secretsmanager_secret.bodmis.name}}@//${local.bodmis_host}:1522/${local.bodmis_service_name}"

  oasys_host              = local.is_dev_or_test ? jsondecode(data.aws_secretsmanager_secret_version.oasys[0].secret_string)["endpoint"] : ""
  oasys_port              = local.is_dev_or_test ? jsondecode(data.aws_secretsmanager_secret_version.oasys[0].secret_string)["port"] : ""
  oasys_service_name      = local.is_dev_or_test ? jsondecode(data.aws_secretsmanager_secret_version.oasys[0].secret_string)["db_name"] : ""
  connection_string_oasys = local.is_dev_or_test ? "oracle://jdbc:oracle:thin:$${${aws_secretsmanager_secret.oasys[0].name}}@//${local.oasys_host}:${local.oasys_port}/${local.oasys_service_name}" : ""

  onr_host              = local.is_dev_or_test ? jsondecode(data.aws_secretsmanager_secret_version.onr[0].secret_string)["endpoint"] : ""
  onr_port              = local.is_dev_or_test ? jsondecode(data.aws_secretsmanager_secret_version.onr[0].secret_string)["port"] : ""
  onr_service_name      = local.is_dev_or_test ? jsondecode(data.aws_secretsmanager_secret_version.onr[0].secret_string)["db_name"] : ""
  connection_string_onr = local.is_dev_or_test ? "oracle://jdbc:oracle:thin:$${${aws_secretsmanager_secret.onr[0].name}}@//${local.onr_host}:${local.onr_port}/${local.onr_service_name}" : ""

  ndelius_host              = local.is_dev_or_test ? jsondecode(data.aws_secretsmanager_secret_version.ndelius[0].secret_string)["endpoint"] : ""
  ndelius_port              = local.is_dev_or_test ? jsondecode(data.aws_secretsmanager_secret_version.ndelius[0].secret_string)["port"] : ""
  ndelius_service_name      = local.is_dev_or_test ? jsondecode(data.aws_secretsmanager_secret_version.ndelius[0].secret_string)["db_name"] : ""
  connection_string_ndelius = local.is_dev_or_test ? "oracle://jdbc:oracle:thin:$${${aws_secretsmanager_secret.ndelius[0].name}}@//${local.ndelius_host}:${local.ndelius_port}/${local.ndelius_service_name}" : ""

  # OASys, ONR and nDelius are currently only included in Dev and Test
  federated_query_connection_strings_map = local.is_dev_or_test ? {
    nomis   = local.connection_string_nomis
    bodmis  = local.connection_string_bodmis
    oasys   = local.connection_string_oasys
    onr     = local.connection_string_onr
    ndelius = local.connection_string_ndelius
    } : {
    nomis  = local.connection_string_nomis
    bodmis = local.connection_string_bodmis
  }

  federated_query_credentials_secret_arns = local.is_dev_or_test ? [
    aws_secretsmanager_secret.nomis.arn,
    aws_secretsmanager_secret.bodmis.arn,
    aws_secretsmanager_secret.oasys[0].arn,
    aws_secretsmanager_secret.onr[0].arn,
    aws_secretsmanager_secret.ndelius[0].arn
    ] : [
    aws_secretsmanager_secret.nomis.arn,
    aws_secretsmanager_secret.bodmis.arn
  ]
}

module "athena_federated_query_connector_oracle" {
  source = "./modules/athena_federated_query_connectors/oracle"

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

  connector_jar_bucket_key              = "third-party/athena-connectors/athena-oracle-2022.47.1.jar"
  connector_jar_bucket_name             = module.s3_artifacts_store.bucket_id
  spill_bucket_name                     = module.s3_working_bucket.bucket_id
  credentials_secret_arns               = local.federated_query_credentials_secret_arns
  project_prefix                        = local.project
  account_id                            = local.account_id
  region                                = local.account_region
  vpc_id                                = data.aws_vpc.shared.id
  subnet_id                             = data.aws_subnet.private_subnets_a.id
  lambda_memory_allocation_mb           = local.federated_query_lambda_memory_mb
  lambda_timeout_seconds                = local.federated_query_lambda_timeout_seconds
  lambda_reserved_concurrent_executions = local.federated_query_lambda_concurrent_executions

  # A map that links catalog names to database connection strings
  connection_strings = local.federated_query_connection_strings_map
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
  count = local.is_dev_or_test ? 1 : 0

  name        = "oasys"
  description = "OASys Athena data catalog"
  type        = "LAMBDA"

  parameters = {
    "function" = module.athena_federated_query_connector_oracle.lambda_function_arn
  }
}

# Adds an Athena data source / catalog for ONR
resource "aws_athena_data_catalog" "onr_catalog" {
  count = local.is_dev_or_test ? 1 : 0

  name        = "onr"
  description = "ONR Athena data catalog"
  type        = "LAMBDA"

  parameters = {
    "function" = module.athena_federated_query_connector_oracle.lambda_function_arn
  }
}

# Adds an Athena data source / catalog for nDelius
resource "aws_athena_data_catalog" "ndelius_catalog" {
  count = local.is_dev_or_test ? 1 : 0

  name        = "ndelius"
  description = "nDelius Athena data catalog"
  type        = "LAMBDA"

  parameters = {
    "function" = module.athena_federated_query_connector_oracle.lambda_function_arn
  }
}