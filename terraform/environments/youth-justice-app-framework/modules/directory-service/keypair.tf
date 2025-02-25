#create keypair for ec2 instances
module "key_pair" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name           = var.management_keypair_name
  create_private_key = true

  tags = local.all_tags
}

#Store the private key in a secret
resource "aws_secretsmanager_secret" "ad_instance_keypair_secret" {
  name        = var.management_keypair_name
  description = "Ket Pair Private key for management instances"
  kms_key_id  = var.ds_managed_ad_secret_key
}

resource "aws_secretsmanager_secret_version" "ad_instance_keypair_secret_version" {
  secret_id     = aws_secretsmanager_secret.ad_instance_keypair_secret.id
  secret_string = module.key_pair.private_key_pem
}