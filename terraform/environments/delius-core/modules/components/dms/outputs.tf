# output "dms_s3_bucket_name" {
#   value = {
#     (var.env_name) = module.s3_bucket_dms_destination.bucket.bucket
#   }
# }


# output "dms_s3_bucket_info" {
#   value = local.dms_s3_bucket_info
# }


# # Output the ARN of the S3 Writer Role so we can avoid attempting
# # to attach policies to roles in other accounts which have not
# # yet been created due to the order in which workflows 
# # process the environments.
# output "dms_s3_writer_role" {
#   value = aws_iam_role.dms_s3_writer_role.arn
# }


output "dms_s3_bucket_info" {
   value = local.dms_s3_bucket_info

}
