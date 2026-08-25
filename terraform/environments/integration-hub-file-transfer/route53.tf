module "r53_file_transfer" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  providers = { aws = aws.core-network-services }
  source    = "terraform-aws-modules/route53/aws"
  version   = "6.5.1"

  name        = local.is-production == false ? "${local.environment}.file-transfer.service.justice.gov.uk" : "file-transfer.service.justice.gov.uk"
  comment     = "Managed by Terraform"
  create_zone = false

  records = {
    ftps = {
      name    = "ftps"
      type    = "A"
      ttl     = 300
      records = [for key, value in aws_eip.this : value.public_ip]
    }
    sftp = {
      name    = "sftp"
      type    = "A"
      ttl     = 300
      records = [for key, value in aws_eip.this : value.public_ip]
    }
    web = {
      name    = "web"
      type    = "CNAME"
      ttl     = 300
      records = [trimprefix(aws_transfer_web_app.this.access_endpoint, "https://")]
    }
  }
}