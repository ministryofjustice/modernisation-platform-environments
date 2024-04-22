# Cost Usage Report

Enable Cost Usage Reports on a 'per-environment' basis.

## Usage

For example:

```terraform
module "cost_usage_report" {

    count = lookup(var.cost_usage_report, "create", false) ? 1 : 0

    source = "../../modules/cost_usage_report"

    providers = {
        aws.us-east-1             = aws.us-east-1
        aws.bucket-replication    = aws
    }

    application_name = var.environment.application_name
    account_number   = var.environment.account_id
    environment      = var.environment.environment
    tags = merge(local.tags)

}
```

triggered by the following in the environment configuration file:

```terraform
  cost_usage_report = {
    create = true
  }
```

This needs to be in each environment configuration file that you want a cost usage report for.

Since each environment is in a different account there's no way to create a single cost usage report for all environments.

## Maintenance

The main challenge with this module is whether/when AWS decide to change their report schema and/or the report format.

The module translates the planetfm-cost-usage-report-create-table.sql file into a terraform 'aws_glue_catalog_table' resource. This has been done manually and is not automated so if the schema changes then the terraform resource will need to be updated. This sql table file is created in the S3 bucket when the `aws_cur_report_definition` resource is created.

This also performs a check to make sure that the s3 bucket is writable by the report definition. Any permission failures will be reported in the terraform plan.
