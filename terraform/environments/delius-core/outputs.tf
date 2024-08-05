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
  sensitive = true
}

output "dms_client_account_ids" {
  value = local.dms_client_account_ids
  sensitive = true
}

output "delius_account_names" {
  value = local.delius_account_names
}

# Output the ID of this account so that we can reference it when 
# reading the remote state file from another account
output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}