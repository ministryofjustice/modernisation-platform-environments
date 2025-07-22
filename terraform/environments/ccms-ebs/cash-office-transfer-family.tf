/*
Due to what appear to be bugs in the aws_s3control_access_grant and awscc_transfer_web_app
resources. Both of these are created an managed manually until those issues can be ironed out.

What should be working configurations have been added to Terraform and left commented
out in:
- modules/transfer-family/grant.tf
- modules/transfer-family/main.tf

Until those bugs are addressed, the below resources are created manually in PRODUCTION ONLY:
- An S3 Transfer Family Web App, using the role ccms-ebs-cashoffice-transfer (created by this module)
- An S3 grant to s3://laa-ccms-inbound-production-mp/* for the entra/identity centre group
  azure-aws-sso-laa-ccms-ebs-s3-cashoffice (which has the group ID c64272c4-30a1-7039-8ffd-af791143da2e)
- A DNS CNAME for ccms-ebs-upload.laa-production.modernisation-platform.service.justice.gov.uk which maps to
  the S3 Transfer Family Web App
*/

module "transfer_family" {
  count                            = local.is-development ? 1 : 0
  source                           = "./modules/transfer-family"
  aws_account_id                   = data.aws_caller_identity.current.account_id
  app_name                         = local.application_name
  bucket_name                      = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  aws_identity_centre_store_arn    = local.application_data.accounts[local.environment].cash_office_idp_arn
  aws_identity_centre_sso_group_id = local.application_data.accounts[local.environment].cash_office_sso_group_id
}

/*
Because of the issues above, the below DNS record relies on a manual input, following the
manual creation of a Web App
*/
resource "aws_route53_record" "transfer_family" {
  count    = local.is-development ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ebs-upload"
  type     = "CNAME"
  ttl      = 300
  records  = ["webapp-01efa045f0de46e9b.transfer-webapp.eu-west-2.on.aws"]
}