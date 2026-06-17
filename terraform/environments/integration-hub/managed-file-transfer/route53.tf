module "r53_managed_file_transfer" {
  source   = "terraform-aws-modules/route53/aws"
  version  = "6.5.0"

  name    = local.is-production == false ? "${local.environment}.managed-file-transfer.service.justice.gov.uk" : "managed-file-transfer.service.justice.gov.uk"
  comment = "Managed by Terraform"

  records = {
    sftp = {
      name    = "sftp"
      type    = "CNAME"
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
