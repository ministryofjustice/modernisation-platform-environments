# Define a variable to hold the list of instance IDs
variable "prod_instance_ids" {
  type    = list
  default = [
    "i-00413756d2dfcf6d2",
    "i-0dba6054c0f5f7a11",
    "i-014bce95a85aaeede",
    "i-0b5ef7cb90938fb82",
    "i-04bbb6312b86648be"

    # Add the IDs of your other instances here...
  ]
}