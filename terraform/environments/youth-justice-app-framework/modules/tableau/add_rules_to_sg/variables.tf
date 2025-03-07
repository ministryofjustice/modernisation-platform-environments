variable "vpc_id" {
  type        = string
  description = "VPC ID."
}


variable "source_sg_id" {
  description = "The ID of Tableau SG."
}


variable "target_sg_id" {
  description = "The ID of Security Group that tableau needs to access."
}


variable "rule" {
  description = "The rule to be assigned."
}

variable "description" {
  description = "Description of the rule."
}

