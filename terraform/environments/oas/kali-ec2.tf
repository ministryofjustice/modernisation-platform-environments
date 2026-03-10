locals {
  userdata_kali = file("${path.module}/files/kali-ec2-update.sh")
}


#kali ssh keys 

resource "tls_private_key" "kali_ssh_key" {
  count     = local.environment == "preproduction" ? 1 : 0
  algorithm = "ED25519"
}


resource "aws_key_pair" "kali_key_pair" {
  count     = local.environment == "preproduction" ? 1 : 0
  key_name   = "${local.application_name}-kali-key"
  public_key = tls_private_key.kali_ssh_key[0].public_key_openssh
}

resource "aws_secretsmanager_secret" "kali_ssh_private_key" {
  count     = local.environment == "preproduction" ? 1 : 0
  name        = "${local.application_name}/kali-ec2-ssh-private-key"
  description = "Private SSH key for kali EC2 instance"
}

resource "aws_secretsmanager_secret_version" "kali_ssh_private_key_version" {
  count     = local.environment == "preproduction" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.kali_ssh_private_key[0].id
  secret_string = jsonencode({
    private_key = tls_private_key.kali_ssh_key[0].private_key_openssh
    public_key  = tls_private_key.kali_ssh_key[0].public_key_openssh
  })
}





resource "aws_instance" "kali_app_instance_new" {
  count = local.environment == "preproduction" ? 1 : 0

  ami                         = "ami-002e3567c9c495d68"
  availability_zone           = "eu-west-2a"
  subnet_id                   = data.aws_subnet.data_subnets_a.id

  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.kali_key_pair[0].key_name
  monitoring                  = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile_new[0].id
  user_data_replace_on_change = true
  user_data                   = base64encode(local.userdata_kali)



}
