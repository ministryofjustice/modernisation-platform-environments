resource "aws_key_pair" "powerbi_gateway_keypair" {
  key_name   = local.environment_configuration.powerbi_gateway_ec2.instance_name
  public_key = local.environment_configuration.powerbi_gateway_ec2.ssh_pub_key
}
