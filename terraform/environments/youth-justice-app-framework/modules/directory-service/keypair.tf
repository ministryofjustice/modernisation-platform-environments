#create keypair for ec2 instances
module "key_pair" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name           = var.management_keypair_name
  create_private_key = true

  tags = local.all_tags
}

# Create a Secrets Manager secret to store the private key
resource "aws_secretsmanager_secret" "key_pair_secret" {
  name = "keypair/${var.management_keypair_name}/private-key"

  tags = local.all_tags
}

# Store the private key inside the secret
resource "aws_secretsmanager_secret_version" "key_pair_secret_version" {
  secret_id     = aws_secretsmanager_secret.key_pair_secret.id
  secret_string = module.key_pair.private_key_pem
}
