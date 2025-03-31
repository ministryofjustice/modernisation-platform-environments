variable "vpc_id" {
  type        = string
  description = "VPC ID."
}


variable "source_sg_id" {
  type        = string
  description = "The ID of Tableau SG."
}


variable "target_sg_id" {
  type        = string
  description = "The ID of Security Group that tableau needs to access."
}


variable "rule" {
  type        = string
  description = "The rule to be assigned."
}

variable "description" {
  type        = string
  description = "Description of the rule."
}

