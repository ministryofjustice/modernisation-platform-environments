module "glue_crawler_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.2.1"

  name = "glue-crawler"

  trust_policy_permissions = {
    TrustedRoleAndServicesToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "Service"
        identifiers = ["glue.amazonaws.com"]
      }]
    }
  }

  policies = {
    aws_glue_service_role = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
    glue_crawler          = module.glue_crawler_iam_policy.arn
  }
}
