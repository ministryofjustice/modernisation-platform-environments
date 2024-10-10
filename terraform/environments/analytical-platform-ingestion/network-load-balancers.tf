# module "datasync_activation_nlb" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

#   source  = "terraform-aws-modules/alb/aws"
#   version = "9.11.0"

#   name = "datasync-activation"

#   load_balancer_type    = "network"
#   vpc_id                = module.connected_vpc.vpc_id
#   subnets               = [module.connected_vpc.private_subnets[0]]
#   create_security_group = false

#   #   security_group_egress_rules = {
#   #     all = {
#   #       ip_protocol = "-1"
#   #       cidr_ipv4   = module.connected_vpc.vpc_cidr_block
#   #     }
#   #   }

#   #   security_group_ingress_rules = {
#   #     all_tcp = {
#   #       from_port   = 80
#   #       to_port     = 80
#   #       ip_protocol = "tcp"
#   #       description = "TCP traffic from GitHub Actions"
#   #       cidr_ipv4   = data.external.external_ip.result["ip"]
#   #     }
#   #   }
# }
