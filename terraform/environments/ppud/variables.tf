###########
# Variables
###########


#########################
# Development Environment
#########################

# Variable in use by Lambda functions

variable "vpc_private_subnet_ids_dev" {
  description = "A list of private subnet IDs for the VPC configuration in the Development environment."
  type        = list(string)
  default     = ["subnet-01815760b71d6a619", "subnet-0131824ef5a4ece01", "subnet-04af8bd9dbbce3310"]
}

variable "vpc_security_group_ids_dev" {
  description = "A list of security group IDs in use by EC2 instances for the VPC configuration in the Development environment."
  type        = list(string)
  default     = ["sg-02ea9c36cc46fa9d7", "sg-099dc76f97a33da2a", "sg-0228625058df0f11b", "sg-0cac4b49823f6ddaf", "sg-0e4e0402865aa3ce8", "sg-06ecaef37c4b3881b", "sg-01c3c678cf336cc95", "sg-0b556b78fd729bc59", "sg-00898a05cfc0ecdc3", "sg-0ee428e8047d6147c"]
}

###########################
# Preproduction Environment
###########################

# Variable in use by Lambda functions

variable "vpc_private_subnet_ids_uat" {
  description = "A list of private subnet IDs for the VPC configuration in the UAT environment."
  type        = list(string)
  default     = ["subnet-07a32195050537180", "subnet-088b0a5bd5fbec323", "subnet-064fc10fb374ea571"]
}

variable "vpc_security_group_ids_uat" {
  description = "A list of security group IDs in use by EC2 instances for the VPC configuration in the UAT environment."
  type        = list(string)
  default     = ["sg-08db11360e6a2c1ed", "sg-03b8ceff365eeca3e", "sg-038cc3700cb9a62eb", "sg-0d8ddeb9445642a35", "sg-03f153349ecce0840"]
}

/*
variable "shared_zone_id" {
  description = "The Route53 zone ID used for DNS validation"
  type        = string
}
*/

########################
# Production Environment
########################

# Variable in use by Lambda functions

variable "vpc_private_subnet_ids_prod" {
  description = "A list of private subnet IDs for the VPC configuration in the Production environment."
  type        = list(string)
  default     = ["subnet-02a1a9cf9e450698b", "subnet-0387a46d6992b6817", "subnet-073947539c44734e7"]
}

variable "vpc_security_group_ids_prod" {
  description = "A list of security group IDs in use by EC2 instances for the VPC configuration in the Production environment."
  type        = list(string)
  default     = ["sg-0fd4949cd2dbd89aa", "sg-06ad7f5180ebcbb8b", "sg-070ae7ce898513c51", "sg-07b7c01ed4de6dc62", "sg-07db12754e48b64c2", "sg-082c9062e3142cf83", "sg-0c70eced587b9709b", "sg-047629d7b14241c12", "sg-06d60ce1cc77ef5a8", "sg-0b339a1e150cb86fc"]
}
