# Stand-in for the cluster VPC's private subnets
terraform {
  required_version = "~> 1.0"
}

output "private_subnets" {
  value = ["subnet-0aaaaaaaaaaaaaaaa", "subnet-0bbbbbbbbbbbbbbbb", "subnet-0cccccccccccccccc"]
}
