This `alb` local Terraform module is taken from the MP provided module - <https://github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer>, and subsequently we have developed from the code there. Below is the README.md taken form the MP module.

# Modernisation Platform Terraform Loadbalancer Module with Access Logs enabled

[![repo standards badge](https://img.shields.io/badge/dynamic/json?color=blue&style=for-the-badge&logo=github&label=MoJ%20Compliant&query=%24.result&url=https%3A%2F%2Foperations-engineering-reports.cloud-platform.service.justice.gov.uk%2Fapi%2Fv1%2Fcompliant_public_repositories%2Fmodernisation-platform-terraform-loadbalancer)](https://operations-engineering-reports.cloud-platform.service.justice.gov.uk/public-github-repositories.html#modernisation-platform-terraform-loadbalancer "Link to report")

A Terraform module that creates application loadbalancer (with loadbalancer security groups) in AWS with logging enabled, s3 to store logs and Athena DB to query logs.

An s3 bucket name can be provided in the module by adding the `existing_bucket_name` variable and adding the bucket name. Otherwise, if no bucket exists one will be created and no variable needs to be set in the module.

A locals for the loadbalancer security group is necessary to satisfy the `loadbalancer_ingress_rules` and `loadbalancer_egress_rules` variables and creates security group rules for the loadbalancer security group. Below is an example:

```
locals {
  loadbalancer_ingress_rules = {
    "lb_ingress" = {
      description     = "Loadbalancer ingress rule from CloudFront"
      from_port       = var.security_group_ingress_from_port
      to_port         = var.security_group_ingress_to_port
      protocol        = var.security_group_ingress_protocol
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
      # cidr_blocks     = ["0.0.0.0/0"]
    }
  }
  loadbalancer_egress_rules = {
    "lb_egress" = {
      description     = "Loadbalancer egress rule"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }
```

Loadbalancer target groups and listeners need to be created separately.

To run queries in Athena do the following:
Go to the Athena console and click on Saved Queries <https://console.aws.amazon.com/athena/saved-queries/home>

Click the new saved query that is named `<custom_name>`-create-table and Run it. You only have to do it once.

Try a query like `select * from lb_logs limit 100;`


## Usage

```hcl

module "alb" {
  source = "./modules/alb"
  providers = {
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
    aws.us-east-1             = aws.us-east-1
  }

  vpc_all                          = local.vpc_all
  application_name                 = local.application_name
  business_unit                    = var.networking[0].business-unit
  public_subnets                   = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id, data.aws_subnet.public_subnets_c.id]
  private_subnets                  = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  tags                             = local.tags
  account_number                   = local.environment_management.account_ids[terraform.workspace]
  environment                      = local.environment
  region                           = "eu-west-2"
  enable_deletion_protection       = false
  idle_timeout                     = 60
  force_destroy_bucket             = true
  security_group_ingress_from_port = 443
  security_group_ingress_to_port   = 443
  security_group_ingress_protocol  = "tcp"
  moj_vpn_cidr_block               = local.application_data.accounts[local.environment].moj_vpn_cidr
  # existing_bucket_name = "" # An s3 bucket name can be provided in the module by adding the `existing_bucket_name` variable and adding the bucket name

  listener_protocol = "HTTPS"
  listener_port     = 443
  alb_ssl_policy    = "ELBSecurityPolicy-TLS-1-2-2017-01" # TODO This enforces TLSv1.2. For general, use ELBSecurityPolicy-2016-08 instead

  services_zone_id     = data.aws_route53_zone.network-services.zone_id
  external_zone_id     = data.aws_route53_zone.external.zone_id
  acm_cert_domain_name = local.application_data.accounts[local.environment].acm_cert_domain_name

  target_group_deregistration_delay = 30
  target_group_protocol             = "HTTP"
  target_group_port                 = 80
  vpc_id                            = data.aws_vpc.shared.id

  healthcheck_interval            = 15
  healthcheck_path                = "/mlra/"
  healthcheck_protocol            = "HTTP"
  healthcheck_timeout             = 5
  healthcheck_healthy_threshold   = 2
  healthcheck_unhealthy_threshold = 3

  stickiness_enabled         = true
  stickiness_type            = "lb_cookie"
  stickiness_cookie_duration = 10800

  # CloudFront settings, to be moved to application_variables.json if there are differences between environments
  cloudfront_default_cache_behavior = {
    smooth_streaming                           = false
    allowed_methods                            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods                             = ["HEAD", "GET"]
    forwarded_values_query_string              = true
    forwarded_values_headers                   = ["Authorization", "CloudFront-Forwarded-Proto", "CloudFront-Is-Desktop-Viewer", "CloudFront-Is-Mobile-Viewer", "CloudFront-Is-SmartTV-Viewer", "CloudFront-Is-Tablet-Viewer", "CloudFront-Viewer-Country", "Host", "User-Agent"]
    forwarded_values_cookies_forward           = "whitelist"
    forwarded_values_cookies_whitelisted_names = ["AWSALB", "JSESSIONID"]
    viewer_protocol_policy                     = "https-only"
  }
  # Other cache behaviors are processed in the order in which they're listed in the CloudFront console or, if you're using the CloudFront API, the order in which they're listed in the DistributionConfig element for the distribution.
  cloudfront_ordered_cache_behavior = {
    "cache_behavior_0" = {
      smooth_streaming                 = false
      path_pattern                     = "*.png"
      min_ttl                          = 0
      allowed_methods                  = ["GET", "HEAD"]
      cached_methods                   = ["HEAD", "GET"]
      forwarded_values_query_string    = false
      forwarded_values_headers         = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy           = "https-only"
    },
    "cache_behavior_1" = {
      smooth_streaming                 = false
      path_pattern                     = "*.jpg"
      min_ttl                          = 0
      allowed_methods                  = ["GET", "HEAD"]
      cached_methods                   = ["HEAD", "GET"]
      forwarded_values_query_string    = false
      forwarded_values_headers         = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy           = "https-only"
    },
    "cache_behavior_2" = {
      smooth_streaming                 = false
      path_pattern                     = "*.gif"
      min_ttl                          = 0
      allowed_methods                  = ["GET", "HEAD"]
      cached_methods                   = ["HEAD", "GET"]
      forwarded_values_query_string    = false
      forwarded_values_headers         = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy           = "https-only"
    },
    "cache_behavior_3" = {
      smooth_streaming                 = false
      path_pattern                     = "*.css"
      min_ttl                          = 0
      allowed_methods                  = ["GET", "HEAD"]
      cached_methods                   = ["HEAD", "GET"]
      forwarded_values_query_string    = false
      forwarded_values_headers         = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy           = "https-only"
    },
    "cache_behavior_4" = {
      smooth_streaming                 = false
      path_pattern                     = "*.js"
      min_ttl                          = 0
      allowed_methods                  = ["GET", "HEAD"]
      cached_methods                   = ["HEAD", "GET"]
      forwarded_values_query_string    = false
      forwarded_values_headers         = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy           = "https-only"
    }
  }
  cloudfront_http_version             = "http2"
  cloudfront_enabled                  = true
  cloudfront_origin_protocol_policy   = "https-only"
  cloudfront_origin_read_timeout      = 60
  cloudfront_origin_keepalive_timeout = 60
  cloudfront_price_class              = "PriceClass_100"
  cloudfront_geo_restriction_type     = "none"
  cloudfront_geo_restriction_location = []
  cloudfront_is_ipv6_enabled          = true
  waf_default_action                  = "BLOCK"

}

```
<!--- BEGIN_TF_DOCS --->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3-bucket"></a> [s3-bucket](#module\_s3-bucket) | github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket | v6.1.1 |

## Resources

| Name | Type |
|------|------|
| [aws_athena_database.lb-access-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/athena_database) | resource |
| [aws_athena_named_query.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/athena_named_query) | resource |
| [aws_athena_workgroup.lb-access-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/athena_workgroup) | resource |
| [aws_lb.loadbalancer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_security_group.lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_elb_service_account.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elb_service_account) | data source |
| [aws_iam_policy_document.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_vpc.shared](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [template_file.lb-access-logs](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_number"></a> [account\_number](#input\_account\_number) | Account number of current environment | `string` | n/a | yes |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name of application | `string` | n/a | yes |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. | `bool` | n/a | yes |
| <a name="input_existing_bucket_name"></a> [existing\_bucket\_name](#input\_existing\_bucket\_name) | The name of the existing bucket name. If no bucket is provided one will be created for them. | `string` | `""` | no |
| <a name="input_force_destroy_bucket"></a> [force\_destroy\_bucket](#input\_force\_destroy\_bucket) | A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable. | `bool` | `false` | no |
| <a name="input_idle_timeout"></a> [idle\_timeout](#input\_idle\_timeout) | The time in seconds that the connection is allowed to be idle. | `string` | n/a | yes |
| <a name="input_loadbalancer_egress_rules"></a> [loadbalancer\_egress\_rules](#input\_loadbalancer\_egress\_rules) | Security group egress rules for the loadbalancer | <pre>map(object({<br>    description     = string<br>    from_port       = number<br>    to_port         = number<br>    protocol        = string<br>    security_groups = list(string)<br>    cidr_blocks     = list(string)<br>  }))</pre> | n/a | yes |
| <a name="input_loadbalancer_ingress_rules"></a> [loadbalancer\_ingress\_rules](#input\_loadbalancer\_ingress\_rules) | Security group ingress rules for the loadbalancer | <pre>map(object({<br>    description     = string<br>    from_port       = number<br>    to_port         = number<br>    protocol        = string<br>    security_groups = list(string)<br>    cidr_blocks     = list(string)<br>  }))</pre> | n/a | yes |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | Public subnets | `list(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS Region where resources are to be created | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to be used by all resources | `map(string)` | n/a | yes |
| <a name="input_vpc_all"></a> [vpc\_all](#input\_vpc\_all) | The full name of the VPC (including environment) used to create resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_athena_db"></a> [athena\_db](#output\_athena\_db) | n/a |
| <a name="output_load_balancer"></a> [load\_balancer](#output\_load\_balancer) | n/a |
| <a name="output_security_group"></a> [security\_group](#output\_security\_group) | n/a |

<!--- END_TF_DOCS --->

## Looking for issues?
If you're looking to raise an issue with this module, please create a new issue in the [Modernisation Platform repository](https://github.com/ministryofjustice/modernisation-platform/issues).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3-bucket"></a> [s3-bucket](#module\_s3-bucket) | github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket | v6.2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_athena_database.lb-access-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/athena_database) | resource |
| [aws_athena_named_query.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/athena_named_query) | resource |
| [aws_athena_workgroup.lb-access-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/athena_workgroup) | resource |
| [aws_lb.loadbalancer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_security_group.lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_elb_service_account.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elb_service_account) | data source |
| [aws_iam_policy_document.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_vpc.shared](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_number"></a> [account\_number](#input\_account\_number) | Account number of current environment | `string` | n/a | yes |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name of application | `string` | n/a | yes |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. | `bool` | n/a | yes |
| <a name="input_existing_bucket_name"></a> [existing\_bucket\_name](#input\_existing\_bucket\_name) | The name of the existing bucket name. If no bucket is provided one will be created for them. | `string` | `""` | no |
| <a name="input_force_destroy_bucket"></a> [force\_destroy\_bucket](#input\_force\_destroy\_bucket) | A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable. | `bool` | `false` | no |
| <a name="input_idle_timeout"></a> [idle\_timeout](#input\_idle\_timeout) | The time in seconds that the connection is allowed to be idle. | `string` | n/a | yes |
| <a name="input_internal_lb"></a> [internal\_lb](#input\_internal\_lb) | A boolean that determines whether the load balancer is internal or internet-facing. | `bool` | `false` | no |
| <a name="input_loadbalancer_egress_rules"></a> [loadbalancer\_egress\_rules](#input\_loadbalancer\_egress\_rules) | Security group egress rules for the loadbalancer | <pre>map(object({<br>    description     = string<br>    from_port       = number<br>    to_port         = number<br>    protocol        = string<br>    security_groups = list(string)<br>    cidr_blocks     = list(string)<br>  }))</pre> | n/a | yes |
| <a name="input_loadbalancer_ingress_rules"></a> [loadbalancer\_ingress\_rules](#input\_loadbalancer\_ingress\_rules) | Security group ingress rules for the loadbalancer | <pre>map(object({<br>    description     = string<br>    from_port       = number<br>    to_port         = number<br>    protocol        = string<br>    security_groups = list(string)<br>    cidr_blocks     = list(string)<br>  }))</pre> | n/a | yes |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | Public subnets | `list(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS Region where resources are to be created | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to be used by all resources | `map(string)` | n/a | yes |
| <a name="input_vpc_all"></a> [vpc\_all](#input\_vpc\_all) | The full name of the VPC (including environment) used to create resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_athena_db"></a> [athena\_db](#output\_athena\_db) | n/a |
| <a name="output_load_balancer"></a> [load\_balancer](#output\_load\_balancer) | n/a |
| <a name="output_security_group"></a> [security\_group](#output\_security\_group) | n/a |
<!-- END_TF_DOCS -->
