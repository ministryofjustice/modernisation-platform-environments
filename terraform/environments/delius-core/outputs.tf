# Supply the name of the S3 Bucket used for Staging DMS Data between environments.
# This is placed in the output to allow it to be referenced in the Terraform state
# file from within another (source/target) environment.
output "dms_s3_bucket_info" {
  value = (
   local.is-development ? module.environment_dev[0].dms_s3_bucket_info :
     local.is-test ? module.environment_test[0].dms_s3_bucket_info :
       local.is-preproduction ? module.environment_preprod[0].dms_s3_bucket_info : null )
  sensitive = true
}