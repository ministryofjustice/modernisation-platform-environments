module "iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=d6e381ccfa95b944149c8b14ba4087e517c57ac7" # v6.8.0

  name = local.component_name

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession",
      ]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${local.environment_management.account_ids["data-platform-production"]}:role/ai-gateway"]
      }]
    }
  }

  policies = {
    ai-gateway = module.iam_policy.arn
  }
}
