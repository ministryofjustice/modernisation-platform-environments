output "oracle_db_instance" {
  value = try(module.environment_dev[0].oracle_db_server_names,
              module.environment_test[0].oracle_db_server_names,
              module.environment_stage[0].oracle_db_server_names,
              module.environment_preprod[0].oracle_db_server_names)
}

output "dms_s3_bucket_info" {
  value = (
   local.is-development ? module.environment_dev[0].dms_s3_bucket_info :
     local.is-test ? module.environment_test[0].dms_s3_bucket_info :
       local.is-preproduction ? module.environment_preprod[0].dms_s3_bucket_info : null )
}