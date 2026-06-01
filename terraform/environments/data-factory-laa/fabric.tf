module "fabric_oidc_provider" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/fabric-oidc-provider?ref=15cea29"

  tenant_id          = local.fabric_tenant_id
  oidc_provider_name = "fabric-s3-access"
}
