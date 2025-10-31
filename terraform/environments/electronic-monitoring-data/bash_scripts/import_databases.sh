environment=$1
account_id=$2
databases=$3

# Initialize Terraform
terraform init --upgrade -reconfigure
terraform workspace select electronic-monitoring-data-$environment
IFS=',' read -r -a databases_array <<< "$databases"

for database in "${databases_array[@]}"; do
    terraform import module.share_dbs_with_roles[0].aws_glue_catalog_database.cadt_databases[\"${database}\"] $account_id:$database
done

# example use: bash import_database.sh development 000111222333 database1_name_in_environment,database2_name_in_environment

