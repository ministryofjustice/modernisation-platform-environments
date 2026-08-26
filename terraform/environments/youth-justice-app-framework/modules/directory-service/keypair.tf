#create keypair for ec2 instances
module "key_pair" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name           = var.management_keypair_name
  create_private_key = true

  tags = local.all_tags
}

#Save private key to secret
resource "aws_secretsmanager_secret" "private_key" {
  #checkov:skip=CKV2_AWS_57:todo add rotation if needed
  #checkov:skip=CKV_AWS_149: it is added
  name        = "yjaf-keypair-rsa-${var.management_keypair_name}"
  description = "Private RSA Key"
  kms_key_id  = var.ds_managed_ad_secret_key
}

#Store secret as key value pair where key is password
# Store secret as key value pair where key is password
resource "aws_secretsmanager_secret_version" "private_key_version" {
  secret_id = aws_secretsmanager_secret.private_key.id

  # Format the secret string with username and password
  secret_string_wo         = module.key_pair.private_key_pem
  secret_string_wo_version = 1

}
