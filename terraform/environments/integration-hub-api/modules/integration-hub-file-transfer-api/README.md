# Integration Hub File Transfer API module

This module owns the complete operational infrastructure for the Integration Hub File Transfer API: API Gateway, bootstrap Lambdas, DynamoDB tables, authentication secrets, deployment IAM and observability.

The calling environment remains responsible for Modernisation Platform provider configuration and resolving resources owned by other stacks, including the Managed File Transfer upload bucket and alarm topics.

Environment-specific API, authentication, transfer client and observability settings are owned by `application_variables.json` in this module.

Verified `terraform-aws-modules` Registry modules manage the API Gateway API and authorizer, API access log group, Lambda functions, DynamoDB tables, Secrets Manager secrets, KMS key, CloudWatch alarms and deployment IAM role. The module's `migrations.tf` moves resources from their extracted direct addresses into these nested Registry module addresses.

API Gateway integrations, routes and stage remain direct resources because the Registry module creates one integration per route and cannot preserve the existing shared integrations. DynamoDB seed items and the CloudWatch dashboard have no equivalent service submodule. Lambda invoke permissions remain direct because the Lambda module uses generated statement ID prefixes, which would replace the existing permissions.