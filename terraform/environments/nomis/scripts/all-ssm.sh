#!/bin/bash
# wrapper script to perform ssm operations across all accounts

accounts="corporate-staff-rostering hmpps-domain-services hmpps-oem nomis nomis-combined-reporting nomis-data-hub planetfm oasys"
environments="development test preproduction production"
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

for account in $accounts; do
  for environment in $environments; do 
    echo $script ${account}-${environment} $@
    $script ${account}-${environment} $@
  done
done
