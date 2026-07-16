#!/bin/bash
# wrapper script to perform ssm operations across all accounts

profiles="corporate-staff-rostering-preproduction
 corporate-staff-rostering-production
 hmpps-domain-services-development
 hmpps-domain-services-test
 hmpps-domain-services-preproduction
 hmpps-domain-services-production
 hmpps-oem-development
 hmpps-oem-test
 hmpps-oem-preproduction
 hmpps-oem-production
 nomis-development
 nomis-test
 nomis-preproduction
 nomis-production
 nomis-combined-reporting-development
 nomis-combined-reporting-test
 nomis-combined-reporting-preproduction
 nomis-combined-reporting-production
 nomis-data-hub-development
 nomis-data-hub-test
 nomis-data-hub-preproduction
 nomis-data-hub-production
 oasys-development
 oasys-test
 oasys-preproduction
 oasys-production
 oasys-national-reporting-test
 oasys-national-reporting-preproduction
 oasys-national-reporting-production
 planetfm-preproduction
 planetfm-production"

for profile in $profiles; do
  [[ ${profile} =~ ^#.* ]] && continue
  account=$(echo $profile | rev | cut -d-  -f2- | rev)

  if [[ -e tfstate/$profile/terraform.tfstate ]]; then
    echo $profile: skipping as already downloaded
  else
    if [[ ! -d tfstate/$profile ]]; then
      mkdir -p tfstate/$profile
    fi
    echo aws s3api get-object --bucket modernisation-platform-terraform-state --key environments/members/$account/$profile/terraform.tfstate tfstate/$profile/terraform.tfstate --profile $profile
    aws s3api get-object --bucket modernisation-platform-terraform-state --key environments/members/$account/$profile/terraform.tfstate tfstate/$profile/terraform.tfstate --profile $profile
  fi
done
