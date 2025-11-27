module "analytical_platform_airflow_auto_approval_dynamodb_table" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.3.0"

  name         = "analytical-platform-airflow-auto-approval"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "approval_status"

  attributes = [
    {
      name = "approval_status"
      type = "S"
    }
  ]

  tags = local.tags
}
