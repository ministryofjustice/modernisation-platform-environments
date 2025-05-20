#create keypair for ec2 instances
module "key_pair" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.1.0"

  key_name           = local.instance_key_name
  create_private_key = true

  tags = local.all_tags
}
