# Quicksight Terraform module

Terraform module to manage Quicksight.

Version using version.txt file for now, we will move to remote modules and git refs later

# Inputs
- **project_name**: (string) Project name
- **environment_name**: (string) Environment name
- **tags**: (Optional) (map(any)) Tags to apply to resources, where applicable.

# Outputs

None

# Quicksight Deployment
This is done through a combination of manual actions and running of both Terraform and AWS CLI scripts:

1. Terraform creates roles and security groups used to create the Quicksight subscription.
2. The Subsite Subscription is created manually.
3. Terraform is rerun, after setting a switch for he encironment to show that the initila manuall set up is complete. At this point Terraform creates a VPN connection and two data sources.
4. Script accets/create_assets.sh is run for the account create a Dashboard along with the analysys, template and data sets it depends on.

