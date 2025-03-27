# Postgres Tickle Lambda used to ensure the DMS Postgres replication slot on read replicas keeps moving
module "postgres-tickle-lambda-testing" {
  #checkov:skip=CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year"
  source = "./modules/domains/postgres-tickle-lambda"


  setup_postgres_tickle_lambda = true
  postgres_tickle_lambda_name  = "dpr-postgres-tickle-testing"
  lambda_code_s3_bucket        = module.s3_artifacts_store.bucket_id
  lambda_code_s3_key           = "build-artifacts/dev-sandbox/digital-prison-reporting-lambdas/jars/digital-prison-reporting-lambdas-vLatest-all.jar"
  lambda_subnet_ids            = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
  lambda_security_group_ids    = [aws_security_group.lambda_generic[0].id]
  secret_arns                  = [for s in data.aws_secretsmanager_secret.dps : s.arn]
}
