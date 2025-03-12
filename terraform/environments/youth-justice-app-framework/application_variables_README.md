# Youth Juastice App Framework - Application Variables

This contans usage information for parameters in the application_variables.json file.vProvided here as json files connot include comments.

## Accounts

**development**
: A sandbox environment used for initial testing of Terraform code and destroyed every Sunday.

**test**: This environment is used for applicaiotn development and initial and system testing.

**preproduction**
: The Pre-Produciton environment used to prove upgrades before tey are applied to Production. It need to be a clost to production as practical.

**production**
: The live enviroment.

## Parameters

**environment_name**
: A unique name for the environment. It is used by the s3 module as a prefix for all S3 bucket names to ensure that they are unique within the AWS region. It should be used whereever an environment specific value is needed.

**allow_s3_replication**
: Used to indicate that S3 replication from the source environment should be enabled. It is used by the s3 module to indication if a policy is to be applied to each bucket to allow access from the source account. When all data has been transferred (e.g. on Cutover or go-live) it is to be changed to false.

**source_account**
: The number of the account from which s3 replication is enabled.

**ldap_secret_arn**
: <TODO> Description needed.

**ad_management_instance_count**
: The number of ec2 Management instances to be created by the ds module.

**desired_number_of_domain_controllers**
: The number of domain controlers to create. Two would be created by default. This allows for 3 in Production to match the old produciton environment.

