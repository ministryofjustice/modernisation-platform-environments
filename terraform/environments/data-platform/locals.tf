#### This file can be used to store locals specific to the member account ####
locals {
  oidc_repositories        = ["ministryofjustice/data-platform-products:*"]
  oidc_default_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"]
}