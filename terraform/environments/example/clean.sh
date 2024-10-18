rm -Rf .terraform
rm .terraform.lock.hcl
terraform init -backend-config=assume_role={role_arn=\"arn:aws:iam::946070829339:role/modernisation-account-terraform-state-member-access\"}
terraform workspace select example-development