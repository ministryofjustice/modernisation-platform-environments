#!/bin/sh

#Set variables
aws_account_id_dest=$1

script_location=modules/quicksight/assets

aws quicksight create-data-set --aws-account-id ${aws_account_id_dest} --cli-input-json file://${script_location}/cli-data-set-rls.json
aws quicksight create-data-set --aws-account-id ${aws_account_id_dest} --cli-input-json file://${script_location}/cli-data-set-outcomesjson
aws quicksight create-data-set --aws-account-id ${aws_account_id_dest} --cli-input-json file://${script_location}/cli-data-set-offence.json
aws quicksight create-data-set --aws-account-id ${aws_account_id_dest} --cli-input-json file://${script_location}/cli-data-set-person.json

aws quicksight create-refresh-schedule --aws-account-id ${aws_account_id_dest} --cli-input-json file://${script_location}/cli-data-set-rls.json
aws quicksight create-refresh-schedule --aws-account-id ${aws_account_id_dest} --cli-input-json file://${script_location}/cli-data-set-outcomesjson
aws quicksight create-refresh-schedule --aws-account-id ${aws_account_id_dest} --cli-input-json file://${script_location}/cli-data-set-offence.json
aws quicksight create-refresh-schedule --aws-account-id ${aws_account_id_dest} --cli-input-json file://${script_location}/cli-data-set-person.json

aws quicksight create-analysis --aws-account-id ${aws_account_id_dest} --cli-input-json file://${script_location}/cli-analysis-definition-toolkit.json

aws quicksight create-template --aws-account-id ${aws_account_id_dest} --cli-input-json file://${script_location}/cli-template-toolkit.json

aws quicksight create-dashboard --aws-account-id ${aws_account_id_dest} --cli-input-json file://${script_location}/cli-dashboard-toolkit.json
