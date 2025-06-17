# AWS provider for the workspace you're working in (every resource will default to using this, unless otherwise specified)
provider "aws" {
  alias  = "analytical-platform-compute-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = !can(regex("githubactionsrolesession|AdministratorAccess|user", data.aws_caller_identity.original_session.arn)) ? null : can(regex("user", data.aws_caller_identity.original_session.arn)) ? "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/${var.collaborator_access}" : "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess"
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "bash"
    args        = ["../scripts/eks-authentication.sh", local.environment_management.account_ids[terraform.workspace], data.aws_eks_cluster.eks.name]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "bash"
      args        = ["../scripts/eks-authentication.sh", local.environment_management.account_ids[terraform.workspace], data.aws_eks_cluster.eks.name]
    }
  }
}
