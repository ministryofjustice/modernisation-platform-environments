#!/bin/bash

set -e

files=$(find . -type f -name *.tf -not -path "*/.terraform/*" -not -path "*/*providers.tf" -not -path "*/*backend.tf")

terraform(){
  for file in $files
  do
    echo
    echo "----------------------------------------------------------------------------------------------------"
    echo "Validating Terraform in file: $file"
    conftest test $file -p policies/terraform
    echo "----------------------------------------------------------------------------------------------------"
  done
}

main() {
  terraform
}

main
