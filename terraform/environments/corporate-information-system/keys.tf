resource "aws_key_pair" "cis" {
  key_name   = "${local.application_name_short}-ssh-key"
  public_key = local.application_data.accounts[local.environment].cis_ec2_key
}