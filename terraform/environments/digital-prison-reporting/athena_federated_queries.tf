resource "aws_serverlessapplicationrepository_cloudformation_stack" "athena_oracle_connector_nomis" {

  name           = "${local.project}-athena-oracle-connector-nomis-${local.env}"
  application_id = "arn:aws:serverlessrepo:us-east-1:${local.account_id}:applications/AthenaOracleConnector"
  capabilities   = [
    "CAPABILITY_IAM"
  ]
  parameters = {
    DefaultConnectionString : "oracle://jdbc:oracle:thin:$${external/dpr-nomis-source-secrets-for-athena-federated-query}@10.26.24.136:1521:CNOMT3"
    LambdaFunctionName : "${local.project}-nomis-connector-${local.env}"
    SecretNamePrefix : "external/dpr-nomis-source-secrets-for-athena-federated-query"
    SecurityGroupIds : "sg-074cee4f1f510ba0d"
    SubnetIds : data.aws_subnet.private_subnets_a.id
    SpillBucket : module.s3_working_bucket.bucket_id
    SpillPrefix : "athena-spill"
    LambdaTimeout : "900"
    LambdaMemory : "3008"
  }
}