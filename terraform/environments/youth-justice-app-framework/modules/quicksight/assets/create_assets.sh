#!/bin/sh
#set -x

#Set variables
aws_account_id=$1

script_location=modules/quicksight/assets

templates=$script_location/templates/*

for f in $templates
do
    file_name=${f##*/}
    cp ./$script_location/templates/$file_name ./${script_location}/run_time/${file_name}
    sed -i "s/\${aws_account_id}/${aws_account_id}/g" ./modules/quicksight/assets/run_time/${file_name} 

done

aws quicksight create-data-set  --cli-input-json file://${script_location}/run_time/cli-data-set-rls.json
aws quicksight create-data-set --cli-input-json file://${script_location}/run_time/cli-data-set-outcomes.json
aws quicksight create-data-set --cli-input-json file://${script_location}/run_time/cli-data-set-offence.json
aws quicksight create-data-set  --cli-input-json file://${script_location}/run_time/cli-data-set-person.json

aws quicksight create-refresh-schedule  --cli-input-json file://${script_location}/run_time/cli-data-set-outcomes-refresh-schedule.json
aws quicksight create-refresh-schedule --cli-input-json file://${script_location}/run_time/cli-data-set-offence-refresh-schedule.json
aws quicksight create-refresh-schedule  --cli-input-json file://${script_location}/run_time/cli-data-set-person-refresh-schedule.json

aws quicksight create-analysis --aws-account-id ${aws_account_id} --cli-input-json file://${script_location}/run_time/cli-analysis-definition-toolkit.json

aws quicksight create-template --cli-input-json file://${script_location}/run_time/cli-template-toolkit.json

aws quicksight create-dashboard --cli-input-json file://${script_location}/run_time/cli-dashboard-toolkit.json
