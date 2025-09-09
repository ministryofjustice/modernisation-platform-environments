variable "vpc_cidr" {
  type        = string
  description = "the CIDR"
  default     = "10.26.24.0/21"
}
variable "subnet_cidrs" {
  type        = string
  description = "list of cidrs - needed for the tfvars bit"
  default     = "10.26.24.0/21"
}
variable "region" {
  type        = string
  description = "Region for here"
  default     = "eu-west-2"
}

variable "ami" {
  type        = string
  description = "ami"
  default     = "ami-05dc21b0a2a063708"
}

variable "instance_type" {
  type        = string
  description = "instance type"
  default     = "eu-west-2"
}

variable "bucket_name" {
  type        = string
  description = "bucket-Name"
  default     = "my-bucket-1234567891"
}

variable "availability_zones" {
  type        = string
  description = "Value for the availability zone"
  default     = "eu-west-2a"
}
