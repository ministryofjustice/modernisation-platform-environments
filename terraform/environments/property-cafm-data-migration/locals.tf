#### This file can be used to store locals specific to the member account ####
locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets    = cidrsubnets(local.application_data.accounts[local.environment].vpc_cidr, 4, 4, 4)

    sftp_users_all = {
    development = {
      "dev_user1" = {
        s3_bucket    = aws_s3_bucket.CAFM.bucket
        ssm_key_name ="/sftp/keys/dev_user1"
      }
    }
  }
  sftp_users = local.sftp_users_all["development"]
}
