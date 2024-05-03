module "managed_prometheus" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/managed-service-prometheus/aws"
  version = "2.2.3"

  workspace_alias = local.application_name

  tags = local.tags
}
