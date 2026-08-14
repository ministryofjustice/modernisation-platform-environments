#### This file can be used to store data specific to the member account ####
data "aws_ssm_parameter" "internal_ca_arn" {
  name = "internal-ca-arn"
  with_decryption = true
}

