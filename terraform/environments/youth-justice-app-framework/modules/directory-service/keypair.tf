#create keypair for ec2 instances
module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name           = var.management_keypair_name
  create_private_key = true

  tags = local.all_tags
}
