##########################
#    Domain Builder TF   # 
##########################

# Domain Builder Backend Lambda function
module "domain_builder_backend_api_Lambda" {
  name      = "${local.project}-domain-builder-backend-api"
  s3_bucket = module.s3_curated_bucket.bucket_id
  s3_key    = "build-artifacts/domain-builder/jars/domain-builder-backend-api-vLatest-all.jar"
  handler   = "io.micronaut.function.aws.proxy.MicronautLambdaHandler"
  runtime   = "java11"
  variables = {
    "POSTGRES_DB_NAME": "domain_builder"
  }

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-domain-builder-backend-${local.environment}"
      Resource_Type = "Lambda"
      Jira          = "DPR-407"
    }
  )
}