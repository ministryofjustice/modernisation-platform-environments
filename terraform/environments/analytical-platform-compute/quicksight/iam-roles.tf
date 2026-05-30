module "quicksight_vpc_connection_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"

  name  = "quicksight-vpc-connection"
  use_name_prefix = false

  trust_policy_permissions = {
    QuickSightExecutionRole = {
      actions = ["sts:AssumeRole", "sts:TagSession"]
      principals = [
        {
          type = "Service"
          identifiers = [
            "quicksight.amazonaws.com"
          ]
        }
      ]
    }
  }

  policies = {
    quicksight_vpc_connection_iam_policy = module.quicksight_vpc_connection_iam_policy.arn
  }

  tags = local.tags
}

module "find_moj_data_quicksight_sa_assumable_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"

  use_name_prefix = false
  trust_policy_permissions = {
    QuickSightExecutionRole = {
      actions = ["sts:AssumeRole", "sts:TagSession"]
      principals = [
        {
          type = "AWS"
          identifiers = [
            "arn:aws:iam::754256621582:role/cloud-platform-irsa-e5ba8827240d2ff3-live",
            "arn:aws:iam::754256621582:role/cloud-platform-irsa-1003dc6e42f4229f-live",
            "arn:aws:iam::754256621582:role/cloud-platform-irsa-25d122a26f9264de-live"
          ]
        }
      ]
    }
  }


  name = "find-moj-data-quicksight"

  policies = {
    find_moj_data_quicksight_policy = module.find_moj_data_quicksight_policy.arn
  }

  tags = local.tags
}
