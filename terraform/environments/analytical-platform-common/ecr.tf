# This ECR is used to store the image built by in https://github.com/ministryofjustice/analytical-platform-jml-report/releases

module "jml_ecr" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source = "terraform-aws-modules/ecr/aws"
   version = "2.3.0"

  repository_name = "analytical-platform-jml-report"
}