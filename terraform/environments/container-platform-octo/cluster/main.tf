###############################################################################
# Container Platform OCTO — EKS Cluster
#
# Thin wrapper calling the shared EKS cluster module from cloud-platform.
###############################################################################

module "eks" {
  source = "../../cloud-platform/modules/eks-cluster"

  cluster_name    = local.cluster_name
  cluster_version = "1.35"
  vpc_id          = data.aws_vpc.selected.id
  subnet_ids      = data.aws_subnets.private.ids

  access_entries = {
    # Platform Engineer access via SSO
    sso-platform-engineer-admin = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.platform_engineer_admin_sso_role.names)}"
      policy_associations = {
        eks-admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    # MP GitHub Actions (MemberInfrastructureAccess) access
    mpe-administrator = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess"
      policy_associations = {
        eks-admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = local.tags
}
