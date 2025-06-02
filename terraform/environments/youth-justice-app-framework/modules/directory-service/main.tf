## Sets Admin secret

resource "random_password" "mad_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "mad_admin_secret" {
  #checkov:skip=CKV2_AWS_57:todo add rotation if needed
  #checkov:skip=CKV_AWS_149: it is added
  name        = "${var.ds_managed_ad_directory_name}_${local.ds_managed_ad_admin_secret_sufix}"
  description = "Administrator Password for AD"
  #kms_key_id  =  var.ds_managed_ad_secret_key # "aws/secretsmanager" # this won't work with cloudformation
}

#Store secret as key value pair where key is password
# Store secret as key value pair where key is password
resource "aws_secretsmanager_secret_version" "mad_admin_secret_version" {
  secret_id = aws_secretsmanager_secret.mad_admin_secret.id

  # Format the secret string with username and password
  secret_string = jsonencode({
    username = "admin",
    password = random_password.mad_admin_password.result
  })
}

## MAD deployment

resource "aws_directory_service_directory" "ds_managed_ad" {
  name                                 = var.ds_managed_ad_directory_name
  short_name                           = var.ds_managed_ad_short_name
  password                             = jsondecode(aws_secretsmanager_secret_version.mad_admin_secret_version.secret_string)["password"]
  edition                              = var.ds_managed_ad_edition
  type                                 = local.ds_managed_ad_type
  desired_number_of_domain_controllers = var.desired_number_of_domain_controllers

  vpc_settings {
    vpc_id     = var.ds_managed_ad_vpc_id
    subnet_ids = [var.private_subnet_ids[0], var.private_subnet_ids[1]]
  }
}

# Retrieve the current DNS IP addresses as output of the above module are not refreshed when they change.
data "aws_directory_service_directory" "built_ad" {
  directory_id = aws_directory_service_directory.ds_managed_ad.id
}

## Sets MAD security group egress
/* #todo duplicate rule?
resource "aws_security_group_rule" "ds_managed_ad_secgroup" {
  type              = "egress"
  description       = "Allowing outbound traffic"
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  security_group_id = aws_directory_service_directory.ds_managed_ad.security_group_id
}
*/
