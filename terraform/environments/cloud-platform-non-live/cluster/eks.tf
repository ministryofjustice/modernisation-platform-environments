# data "aws_vpc" "selected" {
#   filter {
#     name   = "tag:Name"
#     values = ["cloud-platform-non-live-vpc-development"]
#   }
# }

# data "aws_subnets" "selected" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.selected.id]
#   }
#   tags = {
#     Name = "cloud-platform-non-live-vpc-development-private-*"
#   }
# }

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 21.0"

#   name               = "cp-non-live-dev"
#   kubernetes_version = "1.34"

#   addons = {
#     coredns                = {}
#     eks-pod-identity-agent = {
#       before_compute = true
#     }
#     kube-proxy             = {}
#     vpc-cni                = {
#       before_compute = true
#     }
#   }

#   # Optional
#   endpoint_public_access = true

#   # Optional: Adds the current caller identity as an administrator via cluster access entry
#   enable_cluster_creator_admin_permissions = true

#   vpc_id                   = data.aws_vpc.selected.id
#   subnet_ids               = data.aws_subnets.selected.ids
# #   control_plane_subnet_ids = ["subnet-xyzde987", "subnet-slkjf456", "subnet-qeiru789"]

#   # EKS Managed Node Group(s)
#   eks_managed_node_groups = {
#     default = {
#       # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
#       ami_type       = "AL2023_x86_64_STANDARD"
#       instance_types = ["m5.xlarge"]

#       min_size     = 3
#       max_size     = 10
#       desired_size = 5
#     }
#   }

#   tags = {
#     Environment = "dev"
#     Terraform   = "true"
#   }
# }