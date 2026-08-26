# baseline module

Provision common components in your modernisation platform environment:

- ACM certificates
- load balancers
- autoscaling groups
- security groups
- ec2 instances
- iam roles and policies
- Route53 zones and records
- And more...

## Overview

This module is currently used by HMPPS applications (nomis, oasys etc etc.)
which all have similar components to reduce development time and to ensure
consistency between applications.  It also supports what we call
"stacked environments" where multiple test environments are contained
within a single account, e.g. T1, T2, T3 nomis environments all within
the nomis-test account.

The module is essentially just a `for_each` of the relevant resource types.
The variables for each resource type are passed in via an object to make
things easier to manage.

The associated `baseline_presets` module provides pre-canned objects that
you can pass in as variables.  For example, this can easily provide the
resources that you need to enable AMIs built in `core-shared-services-production`

See the `nomis` application for an example of how this is used.  In `nomis`
- `main.tf` contains the terraform for using baseline module
- `locals.tf` contains options common to all environments
- `locals_development.tf` contains options specific to development account
- `locals_test.tf` contains options specific to test account
- `locals_preproduction.tf` contains options specific to preproduction account
- `locals_production.tf` contains options specific to production account

The options from both `locals.tf` and the relevant environment locals.tf file
are merged together and passed into baseline.  For example,
- `locals.tf` defines s3 buckets required for all environments
- `locals_test.tf` defines additional s3 bucket just needed for test account.
