#### Module is made by the moj
#### https://github.com/ministryofjustice/modernisation-platform-terraform-aws-data-firehose



module "example-http" {
  source                       = "github.com/ministryofjustice/modernisation-platform-terraform-aws-data-firehose"
  cloudwatch_log_group_names   = ["yjaf-${var.environment}/user-journey"]
  destination_http_endpoint    = "https://example-url.com/endpoint"
  destination_http_secret_name = "Xsiam-http-api-keys" # optionally specify name of secret to create
  name                         = "Xsiam-http"          # optionally provide name for more descriptive resource names
  tags                         = local.tags
}