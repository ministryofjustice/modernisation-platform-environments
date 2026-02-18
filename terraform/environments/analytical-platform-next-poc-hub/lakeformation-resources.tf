resource "aws_lakeformation_resource" "mojap_next_poc_data_s3" {
  arn      = "arn:aws:s3:::mojap-next-poc-data"
  role_arn = module.lakeformation_registration_iam_role.arn
}
