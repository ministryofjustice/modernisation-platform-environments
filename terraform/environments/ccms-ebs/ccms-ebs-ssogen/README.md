# CCMS SSO Gen Terraform Configuration

This directory contains Terraform configuration for the CCMS Single Sign-On (SSO) Gen infrastructure.

## Files Overview

### `ssogen-certificates.tf`

Manages AWS Certificate Manager (ACM) certificates and DNS validation for the SSO Gen application.

**Key Resources:**

- **`aws_acm_certificate.external`**: Creates an ACM certificate for the primary domain and subject alternative names (SANs)
  - Uses DNS validation method
  - Configured for different domains based on environment (non-production or production)
  - Lifecycle: `create_before_destroy` enabled for zero-downtime certificate renewal

- **`aws_route53_record.external_validation_nonprod`**: Creates DNS validation records in non-production environments
  - Uses `aws.core-vpc` provider
  - Records are created in the Modernisation Platform's Route53 zone

- **`aws_route53_record.external_validation_prod`**: Creates DNS validation records in production environments
  - Uses `aws.core-network-services` provider
  - Records are created in the LAA's Route53 zone

- **`aws_acm_certificate_validation.external_nonprod`**: Validates the ACM certificate in non-production environments
  - Waits for DNS validation records to be created
  - 10-minute timeout for validation

- **`aws_acm_certificate_validation.external_prod`**: Validates the ACM certificate in production environments
  - Waits for DNS validation records to be created
  - 10-minute timeout for validation

**Supported Domains:**

Non-production (dev/test/preproduction):
- `*.laa-development.modernisation-platform.service.justice.gov.uk`
- `*.laa-test.modernisation-platform.service.justice.gov.uk`
- `*.laa-preproduction.modernisation-platform.service.justice.gov.uk`

Production:
- `*.laa.service.justice.gov.uk`

---

### `members-local.tf`

Defines local variables specific to the member AWS account for the CCMS EBS SSO Gen environment.

**Certificate Configuration:**
- `nonprod_domain`: Domain name for non-production environments
- `prod_domain`: Domain name for production (`laa.service.justice.gov.uk`)
- `primary_domain`: Selected based on environment
- `nonprod_sans`: Subject Alternative Names (SANs) for non-production certificates
- `prod_sans`: Subject Alternative Names for production certificates
- `domain_types`: Mapping of domain names to validation record details
- `modernisation_platform_validations`: Filtered validation records for Modernisation Platform domains
- `laa_validations`: Filtered validation records for LAA domains

---

## Environment-Specific Behavior

Both files implement environment-aware logic:

- **Non-production** (dev/test/preproduction):
  - Uses Modernisation Platform subdomains
  - DNS validation via `aws.core-vpc` provider
  - Certificates validated in non-production pipeline

- **Production**:
  - Uses LAA domain (`laa.service.justice.gov.uk`)
  - DNS validation via `aws.core-network-services` provider
  - Certificates validated in production pipeline

---

## Dependencies

These files depend on:
- `data.aws_route53_zone.external` - Modernisation Platform Route53 zone (non-prod)
- `data.aws_route53_zone.laa` - LAA Route53 zone (prod)
- `local.is-production` - Environment flag
- `local.environment` - Environment name
- `var.networking[0].business-unit` - Business unit identifier
- `local.tags` - Common resource tags

---

## Notes

- Certificate renewal uses `create_before_destroy` lifecycle rule to prevent service disruption
- Separate validation logic for non-prod and prod ensures correct DNS provider usage
