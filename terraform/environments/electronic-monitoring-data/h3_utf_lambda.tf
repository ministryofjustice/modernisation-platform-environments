module "h3_lambda_function" {
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash. No commit hash on this module
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.1.2"

  function_name  = "h3-udf"
  description    = "Athena udf for Uber h3 hexes"
  handler        = "com.aws.athena.udf.h3.H3AthenaHandler"
  runtime        = "java11"
  architectures  = ["x86_64"]
  create_package = false
  memory_size    = 4096

  s3_existing_package = {
    bucket = module.s3-lambda-store-bucket.bucket.id
    key    = "h3_uf/binary/aws-h3-athena-udf-1.0-SNAPSHOT.jar"
  }
}
