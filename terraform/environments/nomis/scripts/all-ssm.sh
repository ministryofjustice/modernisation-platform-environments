#!/bin/bash
# wrapper script to perform ssm operations across all accounts

profiles="corporate-staff-rostering-development
 corporate-staff-rostering-test
 corporate-staff-rostering-preproduction
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
 planetfm-development
 planetfm-test
 planetfm-preproduction
 planetfm-production
 oasys-development
 oasys-test
 oasys-preproduction
 oasys-production"

action=$1

if [[ -z $action ]]; then
  echo "Usage: $0 describe|get"
  exit 1
fi

shift
script="./${action}-ssm-parameters.sh"

if [[ ! -x $script ]]; then
  echo "Unexpected action: $action"
  exit 1
fi

for profile in $profiles; do
  [[ ${profile} =~ ^#.* ]] && continue
  echo $script ${profile} $@
  $script ${profile} $@
done
