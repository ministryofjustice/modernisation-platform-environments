data "aws_kms_key" "secrets_manager_common" {
  key_id = "alias/secretsmanager/common"
}


data "aws_eks_cluster" "cluster" {
  name = local.eks_cluster_name
}
