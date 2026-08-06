module "data_platform_eks_iam_oidc_provider" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-data-platform-lakeformation.git//modules/iam-oidc-provider?ref=feat/data-lake-storage"

  url = "https://oidc.eks.eu-west-2.amazonaws.com/id/6DEB8DAAB19F7A5C9762F063B663954A" // data-platform-development
}
