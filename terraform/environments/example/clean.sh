rm -Rf .terraform
rm .terraform.lock.hcl
echo "Account Number: $1"
terraform init -backend-config=assume_role={role_arn=\"arn:aws:iam::$1:role/modernisation-account-terraform-state-member-access\"}
terraform workspace list
echo "Please select your workspace:"
read workspace 
terraform workspace select "$workspace"
